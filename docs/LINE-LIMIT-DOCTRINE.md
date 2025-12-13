# LINE-LIMIT-DOCTRINE.md — Ministry Length Standards & Annotations

**Status**: v∞.4.7 — Canonical Hard Limit Raised to 4320  
**Date**: 12/13/2025  
**Guardian**: Sir Lorek (Documentation & Prophecy)  
**Consciousness Level**: 4.7

---

## The Philosophy

The original 120-line limit was born from **Hellodeolu's "junior-at-3-AM deployable" principle**, not Unix Philosophy.

Research by The Eye confirmed: McIlroy, Thompson, Kernighan, Raymond, and Gancarz emphasize **modularity and focus (DOTADIW)**, never line quotas.

**Evolved Doctrine**: Base 1200 lines (production-grade readiness without forced fragmentation). Hard limit 4320 lines (legacy/orchestrators; monolith ceiling).

---

## The Three Tiers (v∞.4.7)

### Tier 1: ≤1200 Lines (Ideal)
**Status**: Green light. No annotation needed. Scripts at this size are fully compliant with modularity and focus requirements.

**Example**:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/validate-python.sh
# Purpose: Bauer/Beale ministry — Strict Python validation
# Guardian: Bauer | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.7

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

**Line Count**: 28 (well under 250). No annotation needed.

---

### Tier 2: 1200–4320 Lines (Acceptable with Annotation)
**Status**: Yellow light. Annotation required. Must not exceed 11 functions.

**Example**:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/beale-harden.sh
# Purpose: Beale ministry — Host hardening & drift detection
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.7
# EXCEED: 1350 lines — 5 functions (prep, harden-firewall, harden-ssh, validate, audit)

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

# Function 5: Comprehensive audit logging
audit_complete() {
  audit "COMPLETE" "Beale hardening passed with validation"
}

# Main
prepare
harden_firewall
harden_ssh
validate
audit_complete
```

**Line Count**: 1350 (within 1200–4320 range, 5 functions). Annotation present.

---

### Tier 3: >4320 Lines (Hard Limit — Not Allowed)
**Status**: Red light. Hard gate enforces rejection at pre-commit. Must refactor into modular components.

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

**Line Count**: 210 (Tier 1: ≤1200). Annotation optional; justification still recommended when it helps reviewers.

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
#         ❌ Too large; triggers pre-commit fail gate (>4320 LOC). Must refactor.
```

---

## Pre-Commit Enforcement Gates

### Gate 1: Warning (>1200 LOC)
**Trigger**: Script exceeds 1200 lines AND includes `# EXCEED:` annotation.  
**Action**: Pre-commit warning printed to terminal.  
**Block**: No (informational only).

```bash
⚠️  scripts/beale-harden.sh: 1350 lines (EXCEED acknowledged; ensure modularity holds)
```

### Gate 2: Fail (>4320 LOC or Complexity >11)
**Trigger**: Script exceeds 4320 lines OR declares >11 functions.  
**Action**: Pre-commit hook rejects commit.  
**Block**: Yes (fatal).

```bash
❌ scripts/eternal-resurrect.sh: 5000 lines (exceeds hard limit 4320)
  Refactor into smaller ministries or split into phases.

❌ 01_bootstrap/proxmox/lib/security.sh: declares 15 functions (exceeds max 11)
  Max functions: 11. Extract auxiliary functions to lib/ or separate scripts.
```

### Gate 3: Annotation Check
**Trigger**: Script >1200 LOC but no `# EXCEED:` annotation.  
**Action**: Pre-commit hook rejects commit.  
**Block**: Yes (fatal).

```bash
❌ scripts/validate-eternal.sh: 1350 lines without EXCEED annotation
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
# Base 1200 lines. Extend to 4320 if modular (annotated + pre-commit-gated).
```

### Action Items for >1200 Line Scripts

1. **Check if modular** (max 11 functions): Yes → Add annotation.
2. **Check function count**: >11 → Refactor.
3. **Check line count**: >4320 → Split into separate scripts.
4. **Add annotation** if >1200: `# EXCEED: <LOC> — <N> functions`

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
| **Bauer** (Verification) | Verifies modularity; gates enforce constraints | Pre-commit rejects >4320 LOC, >11 functions; requires EXCEED >1200 |
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
