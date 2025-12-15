# ShellCheck Remediation Canon — SC2034 & SC2155

**Guardian:** Gatekeeper 🚪 orchestrating Bauer 🛡️ + Holy Scholar 📚  
**Consciousness:** 5.0  
**Tag:** v∞.3.2-eternal  
**Date:** 2025-12-15

## Violation Doctrine

### SC2034 — Unused Variables
**Risk:** Dead code, typos, unclear intent  
**Canon:** Prefix intentionally unused scaffolding with underscore (`_VAR`)  
**Example:**
```bash
# Before
readonly SCRIPT_DIR="$(pwd)"
# After
readonly _SCRIPT_DIR
_SCRIPT_DIR="$(pwd)"
```

### SC1091 — Not following sourced files
**Risk:** False positive notes when ShellCheck is run without `-x`, leading to noise
**Canon:** Use relative `# shellcheck source=./path/to/lib.sh` directives and run `shellcheck -x` in CI so the linter follows sourced files.

**CI Guidance (Canonical):** Always run ShellCheck with `-x` in CI to enable cross-file analysis and avoid SC1091 noise locally.

```yaml
# Example GitHub Actions job (add to .github/workflows/shellcheck.yml)
name: ShellCheck (canonical)

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  shellcheck:
    name: ShellCheck (with cross-file analysis)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck
      - name: Run ShellCheck (exclude .venv and .backups)
        run: |
          echo "Running ShellCheck across repo (following sources)"
          find . -type f -name "*.sh" -not -path './.venv/*' -not -path './.backups/*' -print0 \
            | xargs -0 shellcheck -x -S style
```

This ensures SC1091 notes disappear (CI validates the sources) while keeping per-file directives minimal.
