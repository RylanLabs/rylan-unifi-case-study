# Follow-Up Tasks - Post Mypy Strict Compliance

## Priority 1: Mypy Duplicate Module Fix (CRITICAL)
**Issue:** Duplicate module 'main' in .audit/mypy-remediation/*.pre-types
**Fix:** Exclude .audit/ from mypy scanning in pyproject.toml
**Command:**
```toml
[tool.mypy]
exclude = [
    # ... existing ...
    '\.audit',  # Already present, verify it works
]
```
Test: mypy --strict app/ fix_fences.py 03_ai_helpdesk/ templates/tests/

Priority 2: Gatekeeper Shebangs (HIGH)
Issue: Missing shebangs in bash scripts Files:

- eternal-resurrect.sh
- 01_bootstrap/certbot_cron/generate-internal-ca.sh
- .backups/.../generate-internal-ca.sh

Fix: Add #!/usr/bin/env bash to each
Test: bash scripts/gatekeeper/validate-bash-standards.sh

Priority 3: Encoding Issues (MEDIUM)
Issue: check-utf8-encoding failures
Investigation needed: Which files have encoding issues? Command: file --mime $(git ls-files) | grep -v utf-8

Priority 4: Ruff Style Warnings (LOW - Optional)
Issue: 28 style warnings (ANN401, ARG001, PT011)
Decision: Address in separate PR or ignore
Examples:

- ANN401: Replace Any with specific types
- ARG001: Rename unused args to _arg
- PT011: Add pytest.raises match parameter

Priority 5: Cleanup Artifacts (LOW)
Issue: Untracked files in repo
Files to review:

- .venv-stubs/ (delete or add to .gitignore)
- .pre-commit-config.yaml.broken (delete)
- pyproject.toml.bak* (delete)
- *.pre-types backups (keep in .audit/ or delete)

Command: Add to .gitignore or git clean -fd
