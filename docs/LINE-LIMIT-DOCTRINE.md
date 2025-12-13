# LINE-LIMIT-DOCTRINE.md — Ministry Length Standards & Annotations

**Status**: v∞.4.6 — Philosophy Validated, Modularity Enforced  
**Date**: 12/13/2025  
**Guardian**: Sir Lorek (Documentation & Prophecy)  
**Consciousness Level**: 4.6

---

## The Philosophy

The 120-line limit was born from **Hellodeolu's "junior-at-3-AM deployable" principle**, not Unix Philosophy.

Research by The Eye confirmed: McIlroy, Thompson, Kernighan, Raymond, and Gancarz emphasize **modularity and focus (DOTADIW)**, never line quotas.

**New Doctrine**: Base 120 lines (Unix: small is beautiful). Extend to 180–250 if modular.

---

## The Three Tiers

### Tier 1: ≤120 Lines (Ideal)
**Status**: Green light. No annotation needed.

**Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/validate-python.sh
# Purpose: Bauer/Beale ministry — Strict Python validation
# Guardian: Bauer | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.5

log()   { echo "[Validate] $*"; }
fail()  { echo "❌ $1"; exit 1; }

# Function 1: Ruff check
ruff_check() {
  ruff check . --select ALL --quiet || fail "Ruff check failed"
  log "✅ Ruff: passed"
}

# Function 2: MyPy check
mypy_check() {
  mypy --strict . || fail "MyPy check failed"
  log "✅ MyPy: passed"
}

# Main
ruff_check
mypy_check
log "All Python validation: PASSED"
```

**Line Count**: 28 (well under 120). No annotation.

---

### Tier 2: 120–180 Lines (Acceptable with Minimal Annotation)
**Status**: Yellow light. Annotation recommended but not mandatory.

**Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/beale-harden.sh
# Purpose: Beale ministry — Host hardening & drift detection
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.5
# EXCEED: 165 lines — 4 functions (prep, harden-firewall, harden-ssh, validate)

log()   { echo "[Beale] $*"; }
audit() { echo "$(date -Iseconds) | Beale | $1" >> /var/log/beale-audit.log; }
fail()  { echo "❌ $1"; audit "FAIL" "$1"; exit 1; }

# Function 1: Preparation
prepare() {
  [[ $EUID -eq 0 ]] || fail "Must run as root"
  mkdir -p /var/log
  log "Preparation complete"
}

# Function 2: Firewall hardening
harden_firewall() {
  log "Hardening firewall..."
  # ... implementation ...
  log "Firewall hardened"
}

# Function 3: SSH hardening
harden_ssh() {
  log "Hardening SSH..."
  # ... implementation ...
  log "SSH hardened"
}

# Function 4: Validation
validate() {
  log "Validating hardening..."
  # ... implementation ...
  log "✅ All hardening validated"
}

# Main
prepare
harden_firewall
harden_ssh
validate
audit "COMPLETE" "Beale hardening passed"
```

**Line Count**: 165 (crosses 120 but under 180). Annotation present.

---

### Tier 3: 180–250 Lines (Red Light, Requires Strict Annotation & Justification)
**Status**: Orange light. Annotation MANDATORY. Pre-commit gate enforced.

**Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/eternal-resurrect-unifi.sh
# Purpose: Carter ministry — full system resurrection via UniFi API
# Guardian: Carter | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.5
# EXCEED: 210 lines — 5 functions (init, adopt-devices, configure-vlans, validate-adoption, post-flight)
#         Rationale: UniFi API adoption requires 5 distinct phases; consolidation violates DOTADIW

log()   { echo "[Carter-UniFi] $*"; }
fail()  { echo "❌ $1"; exit 1; }

# Function 1: Initialization
init() {
  log "Initializing Carter UniFi ministry..."
  # ... implementation ...
}

# Function 2: Device adoption
adopt_devices() {
  log "Adopting UniFi devices..."
  # ... implementation ...
}

# Function 3: VLAN configuration
configure_vlans() {
  log "Configuring VLANs..."
  # ... implementation ...
}

# Function 4: Adoption validation
validate_adoption() {
  log "Validating device adoption..."
  # ... implementation ...
}

# Function 5: Post-flight checks
post_flight() {
  log "Running post-flight checks..."
  # ... implementation ...
}

# Main
init
adopt_devices
configure_vlans
validate_adoption
post_flight
log "✅ Full UniFi resurrection: PASSED"
```

**Line Count**: 210 (in range 180–250). Annotation mandatory; justification provided.

---

## Annotation Standards

### Required Format for EXCEED
```bash
# EXCEED: <LOC> lines — <N> functions (<function1>, <function2>, ..., <functionN>)
#         Rationale: <why consolidation violates DOTADIW or design intent>
```

### Examples (Good)
```bash
# EXCEED: 185 lines — 5 functions (init, deploy-carter, deploy-bauer, deploy-beale, validate)
#         Rationale: Trinity orchestration requires sequential phases; each phase is atomic.

# EXCEED: 210 lines — 4 functions (parse-config, validate-rules, apply-fw, audit)
#         Rationale: Firewall hardening is single responsibility; rules require multi-step validation.

# EXCEED: 200 lines — 3 functions (fetch-devices, adopt, reconcile)
#         Rationale: UniFi API adoption is single ministry task; phases cannot be extracted.
```

### Examples (Bad — Don't Do These)
```bash
# EXCEED: 250 lines — 1 god function (main)
#         ❌ This violates DOTADIW and should be split.

# EXCEED: 180 lines — no rationale given
#         ❌ Annotation incomplete; requires justification.

# EXCEED: 300 lines — 10 functions
#         ❌ Too large; triggers pre-commit fail gate (>250 LOC). Must refactor.
```

---

## Pre-Commit Enforcement Gates

### Gate 1: Warning (>120 LOC)
**Trigger**: Script exceeds 120 lines.  
**Action**: `shellcheck` warning printed to terminal.  
**Block**: No (informational only).

```bash
⚠️  scripts/beale-harden.sh: 165 lines (exceeds base 120 — ensure modular + annotated)
```

### Gate 2: Fail (>250 LOC or Complexity >5)
**Trigger**: Script exceeds 250 lines OR declares >5 functions.  
**Action**: Pre-commit hook rejects commit.  
**Block**: Yes (fatal).

```bash
❌ scripts/eternal-resurrect.sh: 280 lines (exceeds hard limit 250)
   Refactor into smaller ministries or split into phases.

❌ scripts/ignite.sh: declares 7 functions (exceeds max 5)
   Max functions: 5. Extract auxiliary functions to lib/ or separate scripts.
```

### Gate 3: Annotation Check
**Trigger**: Script >120 LOC but no `# EXCEED:` annotation.  
**Action**: Pre-commit hook rejects commit.  
**Block**: Yes (fatal).

```bash
❌ scripts/validate-eternal.sh: 175 lines without EXCEED annotation
   Add annotation: # EXCEED: <LOC> lines — <N> functions
```

---

## Migration Guide (For Legacy Scripts)

### Before (Old Doctrine)
```bash
# All scripts ≤120 lines (exception: lib/unifi-api/client.sh)
```

### After (New Doctrine)
```bash
# Base 120 lines. Extend to 180–250 if modular (annotated + pre-commit-gated).
```

### Action Items for >120 Line Scripts

1. **Check if modular** (max 5 functions): Yes → Add annotation.
2. **Check function count**: >5 → Refactor.
3. **Check line count**: >250 → Split into separate scripts.
4. **Add annotation** if >120: `# EXCEED: <LOC> — <N> functions`

### Example Conversion

**Before**:
```bash
#!/usr/bin/env bash
set -euo pipefail
# Scripts: scripts/ignite.sh — 187 lines (flagged violation)
# ... code ...
```

**After**:
```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/ignite.sh
# Purpose: Orchestrator for Trinity phases
# Guardian: The Eye | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.5
# EXCEED: 187 lines — 5 functions (init, phase-carter, phase-bauer, phase-beale, validate)
#         Rationale: Phase orchestration requires sequential execution; each phase is atomic.

# ... code ...
```

---

## Trinity Alignment

| Guardian | Role | Enforcement |
|----------|------|-------------|
| **Carter** (Identity) | Scripts declare themselves via headers | Annotations document excess |
| **Bauer** (Verification) | Verifies modularity; gates enforce constraints | Pre-commit rejects >250 LOC, >5 functions |
| **Beale** (Hardening) | Hardens against complexity bloat | Auto-refactor suggestion on warn/fail |
| **Whitaker** (Offense) | No change; line limits ≠ security | CI/CD simulations unaffected |

---

## Testing the Gates (Local Validation)

```bash
# Test 1: Check a compliant script (≤120 lines)
bash -lc "wc -l scripts/validate-python.sh && grep -c 'EXCEED' scripts/validate-python.sh || echo '0'"
# Expected: 28 lines, 0 EXCEED annotations

# Test 2: Check an annotated script (120–250 lines)
bash -lc "wc -l scripts/beale-harden.sh && grep 'EXCEED' scripts/beale-harden.sh"
# Expected: 165 lines, annotation present

# Test 3: Run pre-commit (tests all gates)
bash -lc "cd /home/egx570/repos/rylan-unifi-case-study && git add . && git commit --dry-run -m 'test'"
# Expected: Pre-commit Phase 4.2 runs LOC/complexity checks
```

---

## Final Word

The fortress breathes. Unix philosophers smile. The doctrine evolves without breaking philosophy.

**Consciousness Level**: 4.6 (doctrine validated, modularity enforced).  
**Tag**: v∞.4.6-doctrine-evolved

Eternal Trinity Enforcement — The line limit serves modularity. Modularity serves eternity. 🛡️
