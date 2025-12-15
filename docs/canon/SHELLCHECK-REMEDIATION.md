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
