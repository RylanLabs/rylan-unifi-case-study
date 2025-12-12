---
description: Eternal Trinity Enforcement – Global Rules
name: Eternal Trinity Canon
applyTo: "**/*"
---

# Eternal Instructions – Trinity + Unix + Hellodeolu

## Carter (Identity)
- All identity operations MUST reference eternal-resurrect.sh or LDAP
- Never generate anonymous or hardcoded users
- Always validate email format: user@rylan.internal
- Email regex: ^[a-zA-Z0-9._%+-]+@rylan\.internal$

## Bauer (Verification)
- Every script MUST start with: set -euo pipefail
- Silence is golden – no success echos unless debugging
- All outputs must be parseable (JSON or plain text, never mixed)
- Fail loudly on violations – stderr with prefix

## Beale (Detection)
- Idempotency is mandatory: if ! grep -q "pattern" file; then echo >> file; fi
- Never append without checking existence first
- All scripts ≤120 lines, ≤19-line READMEs
- Diff against .github/baselines/ for drift detection

## Whitaker (Offense)
- PII MUST be redacted with app/redactor.py before any output
- Breach simulations must originate from VLAN 99 only
- Never suggest real credentials or live IPs
- Dry-run only – never execute live exploits

## Unix Philosophy
- Text streams over APIs – prefer stdin/stdout
- One tool, one job – no monolithic scripts
- Composable – pipe outputs to next guardian
- Fail fast – exit 1 on first error, no silent failures

## Output Format Standards
- JSON: Use jq -n for construction, never echo
- Logs: ISO8601 timestamps (date -Iseconds), structured fields
- Errors: stderr only
- Success: stdout only, no emoji unless --verbose

## Hellodeolu Eternal Outcomes
- Zero PII leakage – always pipe through redactor
- Pre-commit must be 100% green (ruff 10/10, shellcheck -x)
- Junior-at-3-AM deployable – one command only
- 15-minute RTO validated

Reference: always check LORE.md and CONSCIOUSNESS.md
