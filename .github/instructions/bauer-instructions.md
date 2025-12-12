---
description: Bauer – Trust Nothing, Verify Everything
name: Bauer Eternal
applyTo: ["**/*bauer*.sh", "**/*audit*.sh", "**/*verify*.sh"]
---

# Bauer Domain Instructions

## Verification Protocol
- Always run: bandit -r . && shellcheck -x *.sh && ruff check --fix
- Audit outputs must go to audit-eternal.py
- Firewall rules: ≤10 total, hardware-offload safe
- Verify SSH: PasswordAuthentication no, PubkeyAuthentication yes
- Vault hygiene: no plaintext secrets, .secrets/ mode 600

## Baseline Comparison
- Always diff against .github/baselines/<component>.txt
- If baseline missing: Create it with current state, don't fail
- If diff found: Output unified diff to stderr, exit 1
- Update baseline: bauer-update-baseline.sh --approve

## Audit Log Format
{
  "timestamp": "ISO8601",
  "guardian": "Bauer",
  "check": "firewall_rules|ssh_config|vault_hygiene",
  "status": "pass|fail",
  "violations": [],
  "baseline_hash": "sha256:..."
}

## Failure Modes
- Fail loudly on any violation
- Exit 1 for verification failures
- Exit 2 for baseline missing (warning, not error)
- Exit 3 for tool unavailable (bandit/shellcheck/ruff)
