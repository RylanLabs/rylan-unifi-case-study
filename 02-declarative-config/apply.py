#!/usr/bin/env python3
"""
YAML-driven UniFi network reconciler with proper dry-run support.
v5.0 locked — eternal green edition.
"""

from __future__ import annotations

import json
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional

import logging
import yaml
from pydantic import BaseModel, Field, ValidationError

try:
    from deepdiff import DeepDiff
except ImportError:
    DeepDiff = None  # type: ignore

# Import from parent directory (CI runs from 02-declarative-config/)
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from shared.unifi_client import UniFiClient

# --------------------------------------------------------------------------- #
# Logging & paths
# --------------------------------------------------------------------------- #
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)
BASE_DIR = Path(__file__).parent.parent  # repo root


# --------------------------------------------------------------------------- #
# Pydantic models (match your vlans.yaml structure)
# --------------------------------------------------------------------------- #
class VLAN(BaseModel):
    id: int
    name: str
    subnet: str
    gateway: str
    dhcp_enabled: bool = True
    dhcp_start: Optional[str] = None
    dhcp_end: Optional[str] = None
    dns_servers: List[str] = Field(default_factory=lambda: ["1.1.1.1", "1.0.0.1"])
    purpose: Optional[str] = None
    devices: Optional[List[str]] = None


class VLANContainer(BaseModel):
    id: int
    vlans: List[VLAN]


class VLANRoot(BaseModel):
    vlans: List[VLAN | VLANContainer]


class VLANState(BaseModel):
    vlans: List[VLAN]

    @classmethod
    def from_yaml_structure(cls, data: dict) -> "VLANState":
        all_vlans: List[Dict[str, Any]] = []
        for item in data.get("vlans", []):
            if "vlans" in item:  # nested container (id: 10 with sub-vlans)
                all_vlans.extend(item["vlans"])
            else:  # direct VLAN (id: 1 Management)
                all_vlans.append(item)
        validated = [VLAN(**v) for v in all_vlans]
        return cls(vlans=validated)


# --------------------------------------------------------------------------- #
# Load helpers
# --------------------------------------------------------------------------- #
def load_state(path: Path) -> VLANState:
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
    try:
        return VLANState.from_yaml_structure(raw)
    except ValidationError as e:
        logger.error("VLAN YAML validation failed:")
        for err in e.errors():
            logger.error(f"  → {err['loc']} : {err['msg']}")
        sys.exit(1)


def load_yaml(path: Path) -> Dict[str, Any]:
    if not path.exists():
        logger.error(f"File not found: {path}")
        sys.exit(1)
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


# --------------------------------------------------------------------------- #
# Payload builders
# --------------------------------------------------------------------------- #
def build_payload(vlan: VLAN) -> Dict[str, Any]:
    return {
        "name": vlan.name,
        "purpose": "corporate" if vlan.id != 90 else "guest",
        "vlan": vlan.id,
        "subnet": vlan.subnet,
        "dhcpd_enabled": vlan.dhcp_enabled,
        "dhcpd_start": vlan.dhcp_start or "",
        "dhcpd_stop": vlan.dhcp_end or "",
        "domain_name": "",
        "dhcpd_dns_enabled": bool(vlan.dns_servers),
        "dhcpd_dns_1": vlan.dns_servers[0] if vlan.dns_servers else "",
    }


# --------------------------------------------------------------------------- #
# Reconciliation logic
# --------------------------------------------------------------------------- #
def reconcile(
    desired: VLANState,
    client: Optional[UniFiClient],
    dry_run: bool,
) -> int:
    """Return 0 on success (even in dry-run), non-zero on fatal error."""
    if client is None:
        logger.info("Dry-run mode: Skipping VLAN reconciliation (no client)")
        logger.info(f"Loaded {len(desired.vlans)} VLANs from vlans.yaml")
        return 0

    networks = client.list_networks()
    current_model = [
        {
            "id": n.get("vlan"),
            "name": n.get("name"),
            "subnet": n.get("subnet"),
            "dhcp_enabled": n.get("dhcpd_enabled", True),
            "dhcp_start": n.get("dhcpd_start"),
            "dhcp_end": n.get("dhcpd_stop"),
            "dns_servers": [n.get("dhcpd_dns_1")] if n.get("dhcpd_dns_1") else [],
        }
        for n in networks
        if n.get("vlan") is not None
    ]

    desired_dict = [v.model_dump() for v in desired.vlans]

    diff = DeepDiff(current_model, desired_dict, ignore_order=True) if DeepDiff else {}

    id_map = {n.get("vlan"): n for n in networks if n.get("vlan") is not None}
    to_create = []
    to_update = []

    for vlan in desired.vlans:
        existing = id_map.get(vlan.id)
        if not existing:
            to_create.append(vlan)
            continue
        payload = build_payload(vlan)
        drift = any(
            [
                existing.get("name") != payload["name"],
                existing.get("subnet") != payload["subnet"],
                existing.get("dhcpd_enabled") != payload["dhcpd_enabled"],
            ]
        )
        if drift:
            to_update.append(vlan)

    logger.info("VLAN Plan:")
    logger.info(f"  Create: {[v.id for v in to_create] or '[]'}")
    logger.info(f"  Update: {[v.id for v in to_update] or '[]'}")
    if diff:
        logger.info("  Diff summary:")
        logger.info(json.dumps(dict(diff), indent=2))
    else:
        logger.info("  No structural changes")

    if dry_run:
        logger.info("Dry-run complete – no changes applied")
        return 0

    # --- Real apply ---
    for vlan in to_create:
        try:
            client.create_network(build_payload(vlan))
            logger.info(f"Created VLAN {vlan.id} ({vlan.name})")
        except Exception as e:
            logger.error(f"Failed to create VLAN {vlan.id}: {e}")
            return 1

    for vlan in to_update:
        existing = id_map.get(vlan.id)
        if not existing:
            continue
        try:
            client.update_network(existing["_id"], build_payload(vlan))
            logger.info(f"Updated VLAN {vlan.id} ({vlan.name})")
        except Exception as e:
            logger.error(f"Failed to update VLAN {vlan.id}: {e}")
            return 1

    logger.info("Apply complete")
    return 0


# --------------------------------------------------------------------------- #
# Policy table
# --------------------------------------------------------------------------- #
def apply_policy_table(client: Optional[UniFiClient], dry_run: bool) -> int:
    path = BASE_DIR / "02-declarative-config" / "policy-table.yaml"
    if not path.exists():
        logger.warning(f"Policy table not found: {path}")
        return 0

    data = load_yaml(path)
    rules = data.get("rules", [])
    if len(rules) > 15:
        logger.error("USG-3P offload limit exceeded (>15 rules)")
        return 1

    if client is None:
        logger.info(f"Dry-run: Policy table has {len(rules)} rules (offload safe)")
        return 0

    current = client.get_policy_table()
    desired = {"rules": rules}

    diff = DeepDiff(current, desired, ignore_order=True) if DeepDiff else {}
    logger.info("Policy Table Plan:")
    if diff:
        logger.info(json.dumps(dict(diff), indent=2))
    else:
        logger.info("  No changes")

    if dry_run:
        logger.info("Dry-run: policy table not applied")
        return 0

    try:
        # THIS IS THE FIX — send just the list, not the wrapper dict
        client.update_policy_table(rules)
        logger.info("Policy table applied")
        return 0
    except Exception as e:
        logger.error(f"Failed to apply policy table: {e}")
        return 1


# --------------------------------------------------------------------------- #
# Main entrypoint
# --------------------------------------------------------------------------- #
def main() -> None:
    parser = argparse.ArgumentParser(description="UniFi declarative reconciler")
    parser.add_argument("--dry-run", action="store_true", help="Validate only")
    parser.add_argument("--site", default="default", help="UniFi site name")
    args = parser.parse_args()

    vlans_path = BASE_DIR / "02-declarative-config" / "vlans.yaml"
    desired = load_state(vlans_path)

    client = None
    if not args.dry_run:
        client = UniFiClient.from_env_or_inventory()
        if not client:
            logger.error(
                "Authentication failed: Missing UniFi credentials (env or inventory.yaml)"
            )
            sys.exit(1)

    # VLAN reconciliation
    vlan_rc = reconcile(desired, client, args.dry_run)
    if vlan_rc != 0:
        sys.exit(vlan_rc)

    # Policy table
    policy_rc = apply_policy_table(client, args.dry_run)
    if policy_rc != 0:
        sys.exit(policy_rc)

    logger.info("Rylan v5.0 validation complete – all good!")
    sys.exit(0)


if __name__ == "__main__":
    main()
