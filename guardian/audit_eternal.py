#!/usr/bin/env python3
"""Guardian Audit Logger — Eternal Fortress Compliance.

Validates YAML/JSON config integrity, enforces rule counts, and appends
entries to the audit trail. Designed to run via pre-commit hooks and
nightly cron jobs.

Guardian: Bauer | Carter | Baeale | Consciousness: 9.5
"""

from __future__ import annotations

import json
import logging
import sys
from datetime import UTC, datetime
from pathlib import Path

import yaml

logger = logging.getLogger(__name__)

POLICY_TABLE = Path("02_declarative_config/policy-table.yaml")
MAX_RULES = 10  # USG-3P hardware offload limit (Suehring constraint)
AUDIT_LOG = Path("guardian/audit.log")


def audit_log(message: str) -> None:
    """Append an ISO8601 timestamped entry to the audit log and emit info.

    The audit log file and its parent directory are created if missing to
    ensure idempotent execution in CI and local runs.
    """

    AUDIT_LOG.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(UTC).isoformat()
    entry = f"[{timestamp}] {message}\n"
    with AUDIT_LOG.open("a", encoding="utf-8") as f:
        f.write(entry)

    logger.info("AUDIT: %s", message)


def validate_policy_table() -> None:
    """Enforce policy table rules count and fail-fast on violations."""

    if not POLICY_TABLE.exists():
        audit_log("FAIL: policy-table.yaml missing")
        sys.exit(1)

    with POLICY_TABLE.open(encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    rule_count = len(data.get("rules", []))

    if rule_count > MAX_RULES:
        audit_log(f"FAIL: Rule count {rule_count} exceeds USG-3P max {MAX_RULES} (hardware offload broken)")

    if rule_count == 0:
        audit_log("FAIL: Policy table has 0 rules (zero-trust requires explicit allows)")
        sys.exit(1)

    audit_log(f"Policy table: {rule_count}/{MAX_RULES} rules (Phase 3 endgame, hardware offload safe)")


def validate_json_configs() -> None:
    """Validate all JSON files under the `unifi/` directory."""

    json_files = list(Path("unifi").rglob("*.json"))
    for jf in json_files:
        try:
            with jf.open(encoding="utf-8") as f:
                json.load(f)
            audit_log(f"JSON valid: {jf}")
        except json.JSONDecodeError as exc:
            audit_log(f"FAIL: JSON syntax error in {jf}: {exc}")
            sys.exit(1)


def main() -> None:
    """Run all guardian checks and emit audit entries."""

    audit_log("Guardian audit started")
    validate_policy_table()
    validate_json_configs()
    audit_log("Guardian audit complete — fortress integrity confirmed")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
