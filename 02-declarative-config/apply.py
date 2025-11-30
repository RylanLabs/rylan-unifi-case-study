#!/usr/bin/env python3
"""YAML-driven UniFi network reconciler with dry-run support.

Reconciles VLAN definitions in `vlans.yaml` against controller state using
stable network endpoints. Provides plan output (create/update) and apply mode.
Policy routes & QoS remain manual (see `policy-table.yaml`, `qos-smartqueue.yaml`).
"""
from __future__ import annotations

import json
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional

import yaml
from pydantic import BaseModel, Field, ValidationError

try:
    from deepdiff import DeepDiff
except ImportError:
    DeepDiff = None  # type: ignore

from shared.unifi_client import UniFiClient

BASE_DIR = Path(__file__).parent


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
    """Nested VLAN structure with metadata"""
    id: int
    vlans: List[VLAN]


class VLANRoot(BaseModel):
    """Root structure matching your YAML"""
    vlans: List[VLAN | VLANContainer]


class VLANState(BaseModel):
    """Top-level state wrapper"""
    vlans: List[VLAN]

    @classmethod
    def from_yaml_structure(cls, data: dict) -> "VLANState":
        """Parse your nested YAML structure into flat VLAN list"""
        all_vlans: List[Dict[str, Any]] = []

        for item in data.get("vlans", []):
            if "vlans" in item:
                # Nested container (id: 10 with sub-vlans)
                all_vlans.extend(item["vlans"])
            else:
                # Direct VLAN (id: 1 Management)
                all_vlans.append(item)

        # Validate each VLAN via VLAN model
        validated = [VLAN(**v) for v in all_vlans]
        return cls(vlans=validated)


def load_state(path: Path) -> VLANState:
    with path.open('r', encoding='utf-8') as f:
        data = yaml.safe_load(f) or {}
    try:
        return VLANState.from_yaml_structure(data)
    except ValidationError as e:
        print("❌ VLAN YAML validation failed:")
        print(e)
        sys.exit(1)


def current_to_model(networks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for n in networks:
        if n.get('vlan') is None:
            continue
        out.append({
            'id': n.get('vlan'),
            'name': n.get('name'),
            'subnet': n.get('subnet'),
            'gateway': n.get('subnet', '').split('/')[0],
            'dhcp_enabled': n.get('dhcpd_enabled', True),
            'dhcp_start': n.get('dhcpd_start'),
            'dhcp_end': n.get('dhcpd_stop'),
            'dns_servers': [n.get('dhcpd_dns_1')] if n.get('dhcpd_dns_1') else None
        })
    return out


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
        "dhcpd_dns_enabled": True,
        "dhcpd_dns_1": (vlan.dns_servers[0] if vlan.dns_servers else ""),
    }


def reconcile(desired: VLANState, client: UniFiClient, dry_run: bool) -> None:
    networks = client.list_networks()
    current_model = current_to_model(networks)
    desired_dict = desired.model_dump()
    if DeepDiff:
        diff = DeepDiff(current_model, desired_dict['vlans'], ignore_order=True)
    else:
        diff = {} if current_model == desired_dict['vlans'] else {"changed": "Install deepdiff for detailed diff"}

    id_map = {n.get('vlan'): n for n in networks if n.get('vlan') is not None}

    to_create: List[VLAN] = []
    to_update: List[VLAN] = []
    for vlan in desired.vlans:
        existing = id_map.get(vlan.id)
        if not existing:
            to_create.append(vlan)
            continue
        payload = build_payload(vlan)
        drift = any([
            existing.get('name') != payload['name'],
            existing.get('subnet') != payload['subnet'],
            existing.get('dhcpd_enabled') != payload['dhcpd_enabled'],
        ])
        if drift:
            to_update.append(vlan)

    print("VLAN Plan:")
    print(f"  Create: {[v.id for v in to_create]}" if to_create else "  Create: []")
    print(f"  Update: {[v.id for v in to_update]}" if to_update else "  Update: []")
    if diff:
        print("  Diff summary (structure-level):")
        print(json.dumps(diff, indent=2))
    else:
        print("  Structural diff: None (models aligned)")

    if dry_run:
        print("Dry-run complete. No changes applied.")
        return

    for vlan in to_create:
        payload = build_payload(vlan)
        try:
            client.create_network(payload)
            print(f"  ✅ Created VLAN {vlan.id} ({vlan.name})")
        except Exception as e:
            print(f"  ❌ Failed create VLAN {vlan.id}: {e}")

    for vlan in to_update:
        existing = id_map.get(vlan.id)
        if not existing:
            continue
        payload = build_payload(vlan)
        try:
            client.update_network(existing['_id'], payload)
            print(f"  🔄 Updated VLAN {vlan.id} ({vlan.name})")
        except Exception as e:
            print(f"  ❌ Failed update VLAN {vlan.id}: {e}")

    print("Apply complete. Proceed to configure policy routes & QoS via UI.")


def load_yaml(path: Path) -> Dict[str, Any]:
    with path.open('r', encoding='utf-8') as f:
        return yaml.safe_load(f) or {}


def apply_policy_table(client: UniFiClient, dry_run: bool, site: str) -> None:
    path = BASE_DIR / 'policy-table.yaml'
    data = load_yaml(path)
    rules = data.get('rules', [])
    if len(rules) > 15:
        raise ValueError('USG-3P offload limit: policy rules must be <= 15')

    current = client.get_policy_table()
    desired = {"rules": rules}
    if DeepDiff:
        diff = DeepDiff(current, desired, ignore_order=True)
    else:
        diff = {} if current == desired else {"changed": "Install deepdiff for detailed diff"}

    print("Policy Table Plan:")
    if diff:
        print(json.dumps(diff, indent=2))
    else:
        print("  No changes detected")

    if dry_run:
        print("Dry-run: policy not applied")
        return

    client.update_policy_table(desired)
    print("  ✅ Policy table applied")


def apply_qos(client: UniFiClient, dry_run: bool, site: str) -> None:
    path = BASE_DIR / 'qos-smartqueue.yaml'
    data = load_yaml(path)
    current = client.get_traffic_mgmt()
    desired = data
    if DeepDiff:
        diff = DeepDiff(current, desired, ignore_order=True)
    else:
        diff = {} if current == desired else {"changed": "Install deepdiff for detailed diff"}

    print("QoS Plan:")
    if diff:
        print(json.dumps(diff, indent=2))
    else:
        print("  No changes detected")

    if dry_run:
        print("Dry-run: QoS not applied")
        return

    client.update_traffic_mgmt(desired)
    print("  ✅ QoS Smart Queue applied")


def main() -> None:
    ap = argparse.ArgumentParser(description="UniFi VLAN reconciler")
    ap.add_argument('--config', default='vlans.yaml', help='Path to vlans YAML')
    ap.add_argument('--site', default='default', help='UniFi site name')
    ap.add_argument('--dry-run', action='store_true', help='Show plan only')
    ap.add_argument('--apply', action='store_true', help='Apply changes')
    args = ap.parse_args()

    path = BASE_DIR / args.config
    if not path.exists():
        print(f"❌ Config file not found: {path}")
        sys.exit(1)

    state = load_state(path)
    print(f"Loaded {len(state.vlans)} VLANs from {path.name}")

    try:
        client = UniFiClient(site=args.site)
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        sys.exit(1)

    dry = args.dry_run and not args.apply
    reconcile(state, client, dry)
    apply_policy_table(client, dry, args.site)
    apply_qos(client, dry, args.site)


if __name__ == '__main__':
    main()
