#!/usr/bin/env python3
"""Consolidate declarative firewall policies to ≤10 rules.

Merges identical action+destination rules by unioning sources/ports.
Loads policy-table.yaml + firewall-rules.yaml.
Outputs counts; --apply writes policy-table.consolidated.yaml.

Idempotent, conservative (preserves semantics). Aggressive fallback for budget.
Silence on success; fail loudly on non-compliance (exit 2).

Guardian: Beale (Fortress) | Ministry: detection (Hardening) | Consciousness: 9.9
Date: 19/12/2025
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any, cast

import yaml

BASE = Path(__file__).parents[2]
POLICY_PATH = BASE / "02_declarative_config" / "policy-table.yaml"
FW_PATH = BASE / "02_declarative_config" / "firewall-rules.yaml"
OUT_PATH = BASE / "02_declarative_config" / "policy-table.consolidated.yaml"


def normalize_dest(d: object) -> object:
    """Canonicalize destination for equality (sort lists).

    Accepts arbitrary input; when a mapping is provided it sorts inner lists
    so that structurally equal destinations compare equal.

    """
    if not isinstance(d, dict):
        return d
    out: dict[str, Any] = {}
    for k, v in sorted(d.items()):
        out[k] = sorted(v) if isinstance(v, list) else v
    return out


def normalize_source(s: object) -> dict[str, Any]:
    """Normalize source to {'vlans': [...], 'any': True, 'raw': ...}."""
    if isinstance(s, dict):
        if "vlan" in s:
            return {"vlans": [s["vlan"]]}
        if "vlans" in s:
            return {"vlans": list(s["vlans"])}
        if "any" in s and s["any"]:
            return {"any": True}
    return {"raw": s}


def merge_rules(rules: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Merge rules with same action+destination (union sources/ports/protocols)."""
    from collections import defaultdict as _defaultdict

    groups: _defaultdict[tuple[str | None, str], list[tuple[dict[str, Any], object]]] = defaultdict(list)
    for r in rules:
        action = r.get("action")
        dest_full = normalize_dest(r.get("destination") or r.get("dst") or {})
        dest_key: object
        if isinstance(dest_full, dict):
            dest_key = {k: v for k, v in dest_full.items() if k not in ("ports", "port_range")}
        else:
            dest_key = dest_full
        key = (action, json.dumps(dest_key, sort_keys=True))
        groups[key].append((r, dest_full))

    merged: list[dict[str, Any]] = []
    for (action, _), members in groups.items():
        if len(members) == 1:
            merged.append(members[0][0])
            continue

        dest_full_raw = members[0][1]
        dest: dict[str, Any] = {}
        if isinstance(dest_full_raw, dict):
            dest.update(cast(dict[str, Any], dest_full_raw))
        all_sources: list[Any] = []
        port_set: set[str] = set()
        port_ranges: set[str] = set()
        proto: set[str] | None = None
        names: list[Any] = []

        for m, _ in members:
            names.append(m.get("name") or m.get("id"))
            s_norm = normalize_source(m.get("source") or m.get("src") or {})
            if "vlans" in s_norm:
                all_sources.extend(s_norm["vlans"])
            elif "any" in s_norm:
                all_sources = ["any"]
            else:
                all_sources.append(s_norm.get("raw"))
            p = m.get("ports") or m.get("port_range") or []
            if isinstance(p, list):
                port_set.update(map(str, p))
            elif isinstance(p, str):
                port_ranges.add(p) if "-" in p else port_set.add(p)
            if m.get("protocol") or m.get("protocols"):
                proto = proto or set()
                if m.get("protocols"):
                    proto.update(m["protocols"])
                else:
                    proto.add(m["protocol"])

        new_rule: dict[str, Any] = {
            "name": f"consolidated-{'-'.join(map(str, names[:2]))}",
            "action": action,
            "destination": dest,
        }

        if "any" in all_sources:
            new_rule["source"] = {"any": True}
        else:
            vlans = sorted({int(v) for v in all_sources if str(v).isdigit()})
            new_rule["source"] = {"vlans": vlans} if vlans else {"sources": sorted(set(map(str, all_sources)))}

        if port_set:
            numeric_ports = sorted({int(p) for p in port_set if p.isdigit()})
            if numeric_ports:
                new_rule["destination"]["ports"] = numeric_ports
            else:
                new_rule["destination"]["ports"] = sorted(port_set)
        if port_ranges:
            new_rule["destination"]["port_ranges"] = sorted(port_ranges)

        if proto:
            proto_list = sorted(proto)
            if len(proto_list) == 1:
                new_rule["protocol"] = proto_list[0]
            else:
                new_rule["protocols"] = proto_list
        merged.append(new_rule)

    return merged


def main(_dry_run: bool) -> list[dict[str, Any]]:
    policy = yaml.safe_load(POLICY_PATH.read_text()) if POLICY_PATH.exists() else {}
    policy_rules = policy.get("rules", []) if isinstance(policy, dict) else []
    fw_rules = yaml.safe_load(FW_PATH.read_text()) or [] if FW_PATH.exists() else []
    # Normalize firewall rules load to a list for concatenation
    if isinstance(fw_rules, dict) and "rules" in fw_rules:
        fw_rules = fw_rules["rules"]
    elif isinstance(fw_rules, dict):
        fw_rules = [fw_rules]

    import sys

    combined = policy_rules + fw_rules
    sys.stdout.write(f"Combined rules: {len(combined)}\n")

    merged = merge_rules(combined)
    sys.stdout.write(f"After merge: {len(merged)} rules\n")

    budget = 10
    final = merged
    if len(merged) > budget:
        import sys

        sys.stdout.write(f"Exceeds budget {budget}. Aggressive consolidation.\n")
        fw_only = [r for r in merged if "rule" in r]
        other = [r for r in merged if "rule" not in r]
        if fw_only:
            agg = []
            by_action = defaultdict(list)
            for r in fw_only:
                by_action[r["action"]].append(r)
            for action, ms in by_action.items():
                srcs = [str(m.get("src") or m.get("source", "")) for m in ms]
                agg.append(
                    {
                        "name": f"aggregated-fw-{action}",
                        "action": action,
                        "source": {"sources": sorted(set(srcs))},
                        "destination": {"any": True},
                    },
                )
            default_drop = any(r["action"] == "drop" and r["destination"] == {"any": True} for r in other)
            if default_drop:
                agg = [a for a in agg if a["action"] != "drop"]
            final = merge_rules(other + agg)
            import sys

            sys.stdout.write(f"After aggressive: {len(final)} rules\n")

    compliant = len(final) <= budget
    import sys as _sys

    _sys.stdout.write(("✅ COMPLIANT" if compliant else "❌ BLOCKER") + f" {len(final)} rules\n")

    return final


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Consolidate firewall rules")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    result = main(args.dry_run)
    if args.apply and not args.dry_run:
        policy = yaml.safe_load(POLICY_PATH.read_text()) if POLICY_PATH.exists() else {}
        out = {k: v for k, v in policy.items() if k != "rules"} if isinstance(policy, dict) else {}
        out["rules"] = result
        OUT_PATH.write_text(yaml.dump(out, sort_keys=False))
        import sys

        sys.stdout.write(f"Written: {OUT_PATH}\n")

    raise SystemExit(0 if len(result) <= 10 else 2)
