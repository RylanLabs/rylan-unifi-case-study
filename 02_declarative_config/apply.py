#!/usr/bin/env python3
"""YAML-driven UniFi network reconciler with proper dry-run support.

v5.0 locked — eternal green edition.
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, Field, ValidationError

try:
    from deepdiff import DeepDiff
except ImportError:
    DeepDiff = None  # type: ignore[assignment]

# Import from parent directory
sys.path.insert(0, str(Path(__file__).parent.parent))
from shared.unifi_client import UniFiClient

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
logger = logging.getLogger("fortress")

BASE_DIR = Path(__file__).parent.parent
GUEST_VLAN_ID = 90
MAX_OFFLOAD_RULES = 15


# --------------------------------------------------------------------------- #
# Pydantic models
# --------------------------------------------------------------------------- #


class VLAN(BaseModel):
    """VLAN configuration model."""

    id: int
    name: str
    subnet: str
    gateway: str
    dhcp_enabled: bool = True
    dhcp_start: str | None = None
    dhcp_end: str | None = None
    dns_servers: list[str] = Field(default_factory=lambda: ["1.1.1.1", "1.0.0.1"])
    purpose: str | None = None
    devices: list[str] | None = None


class VLANContainer(BaseModel):
    """Container for nested VLAN groups."""

    id: int
    vlans: list[VLAN]


class VLANRoot(BaseModel):
    """Root VLAN structure."""

    vlans: list[VLAN | VLANContainer]


class VLANState(BaseModel):
    """Flattened VLAN state."""

    vlans: list[VLAN]

    @classmethod
    def from_yaml_structure(cls, data: dict) -> VLANState:
        """Parse nested YAML structure into flat VLAN list."""
        all_vlans: list[dict[str, Any]] = []
        for item in data.get("vlans", []):
            if "vlans" in item:  # nested container
                all_vlans.extend(item["vlans"])
            else:
                all_vlans.append(item)
        return cls(vlans=[VLAN(**v) for v in all_vlans])


# --------------------------------------------------------------------------- #
# Load helpers
# --------------------------------------------------------------------------- #


def load_state(path: Path) -> VLANState:
    """Load and validate VLAN state from YAML."""
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
    try:
        return VLANState.from_yaml_structure(raw)
    except ValidationError:
        logger.exception("VLAN YAML validation failed")
        sys.exit(1)


def load_yaml(path: Path) -> dict[str, Any]:
    """Load YAML file."""
    if not path.exists():
        logger.error("File not found: %s", path)
        sys.exit(1)
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


# --------------------------------------------------------------------------- #
# Payload builders
# --------------------------------------------------------------------------- #


def build_payload(vlan: VLAN) -> dict[str, Any]:
    """Build UniFi API payload from VLAN model."""
    return {
        "name": vlan.name,
        "purpose": "corporate" if vlan.id != GUEST_VLAN_ID else "guest",
        "vlan": vlan.id,
        "subnet": vlan.subnet,
        "networkgroup": "LAN",
        "dhcpd_enabled": vlan.dhcp_enabled,
        "dhcp_range_start": vlan.dhcp_start,
        "dhcp_range_stop": vlan.dhcp_end,
        "dns1": vlan.dns_servers,
        "dns2": vlan.dns_servers if len(vlan.dns_servers) > 1 else "",
    }


# --------------------------------------------------------------------------- #
# Reconciliation logic
# --------------------------------------------------------------------------- #


def reconcile(  # noqa: C901, PLR0912
    desired: VLANState,
    client: UniFiClient | None,
    *,
    dry_run: bool,
) -> int:
    """Return 0 on success (even in dry-run), non-zero on fatal error."""
    if client is None:
        logger.info("Dry-run mode: Skipping VLAN reconciliation (no client)")
        logger.info("Loaded %d VLANs from vlans.yaml", len(desired.vlans))
        return 0

    existing_networks = client.list_networks()
    existing_by_vlan = {net.get("vlan"): net for net in existing_networks if "vlan" in net}

    to_create: list[VLAN] = []
    to_update: list[VLAN] = []
    diff = {}

    for vlan in desired.vlans:
        payload = build_payload(vlan)
        existing = existing_by_vlan.get(vlan.id)

        if not existing:
            to_create.append(vlan)
        else:
            drift = any(
                [
                    existing.get("name") != payload["name"],
                    existing.get("subnet") != payload["subnet"],
                    existing.get("dhcpd_enabled") != payload["dhcpd_enabled"],
                ],
            )
            if drift:
                to_update.append(vlan)
                if DeepDiff:
                    diff[vlan.id] = DeepDiff(existing, payload, ignore_order=True)

    logger.info("VLAN Plan:")
    logger.info("  Create: %s", [v.id for v in to_create] or "[]")
    logger.info("  Update: %s", [v.id for v in to_update] or "[]")
    if diff:
        logger.info("  Diff summary:")
        for vid, delta in diff.items():
            logger.info("    VLAN %d: %s", vid, delta)

    if dry_run:
        logger.info("Dry-run complete - no changes applied")
        return 0

    # Apply creates
    errors = []
    for vlan in to_create:
        try:
            client.create_network(build_payload(vlan))
            logger.info("Created VLAN %d (%s)", vlan.id, vlan.name)
        except Exception:  # noqa: PERF203
            logger.exception("Failed to create VLAN %d", vlan.id)
            errors.append(vlan.id)

    # Apply updates
    for vlan in to_update:
        existing = existing_by_vlan[vlan.id]
        try:
            client.update_network(existing["_id"], build_payload(vlan))
            logger.info("Updated VLAN %d (%s)", vlan.id, vlan.name)
        except Exception:
            logger.exception("Failed to update VLAN %d", vlan.id)
            errors.append(vlan.id)

    return 1 if errors else 0


# --------------------------------------------------------------------------- #
# Policy table
# --------------------------------------------------------------------------- #


def apply_policy_table(client: UniFiClient | None, *, dry_run: bool) -> int:  # noqa: ARG001
    """Apply firewall policy table."""
    path = BASE_DIR / "02_declarative_config" / "policy-table.yaml"
    if not path.exists():
        logger.warning("Policy table not found: %s", path)
        return 0

    data = load_yaml(path)
    rules = data.get("rules", [])
    if len(rules) > MAX_OFFLOAD_RULES:
        logger.error("USG-3P offload limit exceeded (>%d rules)", MAX_OFFLOAD_RULES)
        return 1

    if client is None:
        logger.info("Dry-run: Policy table has %d rules (offload safe)", len(rules))
        return 0

    try:
        client.update_policy_table(rules)
        logger.info("Policy table applied")
    except Exception:
        logger.exception("Failed to apply policy table")
        return 1

    return 0


# --------------------------------------------------------------------------- #
# Main entrypoint
# --------------------------------------------------------------------------- #


def main() -> None:
    """Execute UniFi network reconciliation."""
    parser = argparse.ArgumentParser(description="UniFi declarative reconciler")
    parser.add_argument("--dry-run", action="store_true", help="Validate only")
    args = parser.parse_args()

    if args.dry_run:
        client = None
        logger.info("Dry-run mode enabled: validation only")
    else:
        client = UniFiClient.from_env()
        if not client:
            logger.error(
                "Authentication failed: Missing UniFi credentials " "(env or inventory.yaml)",
            )
            sys.exit(1)

    vlan_rc = reconcile(load_state(Path("vlans.yaml")), client, dry_run=args.dry_run)
    policy_rc = apply_policy_table(client, dry_run=args.dry_run)

    if vlan_rc or policy_rc:
        sys.exit(vlan_rc or policy_rc)

    logger.info("Rylan v5.0 validation complete - all good!")
    sys.exit(0)


# --------------------------------------------------------------------------- #
# Render helper (for migration engine)
# --------------------------------------------------------------------------- #


def render_desired_to_runtime(yaml_file: str, json_out: str) -> None:
    """Idempotent: Render YAML to JSON for migration engine."""
    yaml_path = Path(yaml_file)
    if not yaml_path.exists():
        logger.warning("%s missing - skipping render", yaml_file)
        return

    with yaml_path.open(encoding="utf-8") as f:
        data = yaml.safe_load(f)

    # Convert YAML list to JSON dict (e.g., vlans: [items] → {"1": item})
    if isinstance(data, dict) and data:
        first_key = next(iter(data.keys()))
        json_data = {str(i + 1): item for i, item in enumerate(data[first_key])}
    else:
        json_data = {}

    json_path = Path(json_out)
    with json_path.open("w", encoding="utf-8") as f:
        json.dump(json_data, f, indent=2)

    logger.info("Rendered %s -> %s", yaml_file, json_out)


if __name__ == "__main__":
    main()
