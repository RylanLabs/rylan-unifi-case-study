#!/usr/bin/env python3
"""Guardian Audit Logger — Eternal Fortress Compliance

Validates YAML/JSON config integrity, enforces rule count, logs all changes to audit trail.
Runs pre-commit and nightly via cron.

Carter (operational rigor) + Bauer (audit discipline) + Suehring (security baseline).
"""

import sys
import yaml
import json
from pathlib import Path
from datetime import datetime

POLICY_TABLE = Path("02-declarative-config/policy-table.yaml")
MAX_RULES = 15
LOCKED_RULES = 10
AUDIT_LOG = Path("guardian/audit.log")


def audit_log(message: str):
    """Append timestamped entry to audit log."""
    timestamp = datetime.utcnow().isoformat() + "Z"
    with AUDIT_LOG.open("a") as f:
        f.write(f"[{timestamp}] {message}\n")
    print(f"✅ {message}")


def validate_policy_table():
    """Enforce exactly 10 rules (Phase 2 locked)."""
    if not POLICY_TABLE.exists():
        audit_log("FAIL: policy-table.yaml missing")
        sys.exit(1)

    with POLICY_TABLE.open() as f:
        data = yaml.safe_load(f)

    rule_count = len(data.get("rules", []))

    if rule_count != LOCKED_RULES:
        audit_log(f"FAIL: Expected {LOCKED_RULES} rules, got {rule_count}")
        sys.exit(1)

    if rule_count > MAX_RULES:
        audit_log(f"FAIL: Rule count {rule_count} exceeds USG-3P max {MAX_RULES}")
        sys.exit(1)

    audit_log(f"Policy table: {rule_count} rules (Phase 2 locked, offload safe)")


def validate_json_configs():
    """Validate all JSON files in unifi/ directory."""
    json_files = list(Path("unifi").rglob("*.json"))
    for jf in json_files:
        try:
            with jf.open() as f:
                json.load(f)
            audit_log(f"JSON valid: {jf}")
        except json.JSONDecodeError as e:
            audit_log(f"FAIL: JSON syntax error in {jf}: {e}")
            sys.exit(1)


def main():
    """Run all guardian checks."""
    audit_log("Guardian audit started")
    validate_policy_table()
    validate_json_configs()
    audit_log("Guardian audit complete — fortress integrity confirmed")


if __name__ == "__main__":
    main()
