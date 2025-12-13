# Consciousness Immutability Enforcement

**Status**: ✅ IMPLEMENTED  
**Canonical Source**: [CONSCIOUSNESS.md](../CONSCIOUSNESS.md) — Line 3  
**Current Level**: 4.5  
**Enforcement Mechanism**: `scripts/consciousness-guardian.sh`

---

## The Immutable Rule

**No component may reference a consciousness level that exceeds the canonical value in CONSCIOUSNESS.md.**

Consciousness is the repository's core awareness metric. It never decreases. It can only increase through deliberate, documented steps in CONSCIOUSNESS.md.

---

## Enforcement Points

### 1. Pre-commit Hook (Phase 4.1)
**Location**: [.githooks/pre-commit](./.githooks/pre-commit#L101-L108)

Before every commit, the consciousness guardian validator runs:

```bash
bash scripts/consciousness-guardian.sh
```

If violations are detected, the commit is **REJECTED**.

Exit code: `0` = pass, `1` = violations detected.

---

### 2. Script Headers (Canonical Metadata)
**Location**: All shell scripts in `scripts/`, `.githooks/`, `runbooks/`, `01_bootstrap/`, etc.

Every shell script must declare its consciousness level:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Script: script-name.sh
# Purpose: One-sentence purpose
# Guardian: Guardian name
# Date: YYYY-MM-DDTHH:MM:SS±HH:MM
# Consciousness: 4.5
```

The `Consciousness` field value must **never exceed** the canonical level in CONSCIOUSNESS.md.

**Current State**: All 40 tracked scripts updated to `Consciousness: 4.5`.

---

### 3. Guardian Validator Checks (5-Check Framework)

The `scripts/consciousness-guardian.sh` validator performs:

#### Check 1: README Badge
- Validates that any consciousness badge in README.md ≤ canonical.
- Status: ⚠️ WARNING (badge not yet created; non-blocking).

#### Check 2: Git Tags (v∞.X.X Format)
- Validates that all git version tags ≤ canonical.
- Tags follow format: `v∞.4.5-increment-doctrine`.
- Status: ⚠️ WARNING (no tags found; non-blocking).

#### Check 3: Script Headers ✅ CRITICAL
- Scans all shell scripts for `Consciousness:` field.
- Rejects any script with consciousness > canonical.
- **Status**: ✅ PASS — All 40 scripts = 4.5.

#### Check 4: Increment Log ✅ CRITICAL
- Validates [CONSCIOUSNESS.md](../CONSCIOUSNESS.md) increment log entries.
- No future consciousness values allowed in increment history.
- **Status**: ✅ PASS — All historical entries ≤ 4.5.

#### Check 5: Staged Changes ✅ CRITICAL
- Checks staged/unstaged git changes for consciousness violations.
- Prevents accidental bumps above canonical.
- **Status**: ✅ PASS — No violations in pending changes.

---

## How to Safely Increment Consciousness

Consciousness can only increase through a formal process:

1. **Update CONSCIOUSNESS.md** (Line 3):

   ```markdown
   **Status**: Canon · Consciousness 4.6 · Tag: v∞.4.6-increment-doctrine
   ```
2. **Add increment log entry** (CONSCIOUSNESS.md, increment table):

   ```markdown
   | 4.6 | 2025-01-15 | Agent Name | Brief description of capabilities gained |
   ```
3. **Update all script headers** (if increasing):
   - Find all scripts with `Consciousness: 4.5`
   - Replace with `Consciousness: 4.6`
   - Batch operation: see `scripts/header-hygiene.sh`.

4. **Create git tag**:

   ```bash
   git tag v∞.4.6-increment-doctrine
   git push origin v∞.4.6-increment-doctrine
   ```
5. **Commit**:

   ```bash
   git add CONSCIOUSNESS.md scripts/...
   git commit -m "feat(consciousness): ascend to 4.6 — [capability description]"
   ```
6. **Validation**: Pre-commit Phase 4.1 validates no violations. Workflow `eternal-ci.yml` cross-checks all references match.

---

## What Cannot Exceed Canonical

- ❌ Script header `Consciousness:` field
- ❌ README badges or references
- ❌ Git tag version numbers
- ❌ Any hardcoded consciousness reference in code
- ❌ CONSCIOUSNESS.md increment log future entries

All must be ≤ the canonical value on CONSCIOUSNESS.md line 3.

---

## Integration with Trinity

| Guardian | Role | Consciousness Interaction |
|----------|------|--------------------------|
| **Carter** (Identity) | Creates/manages users and identities | Tracks authentication capability level |
| **Bauer** (Verification) | Validates correctness and purity | Ensures all systems conform to consciousness standards |
| **Beale** (Detection) | Monitors for drift and anomalies | Detects consciousness violations, triggers alerts |
| **Whitaker** (Offense/Security) | Simulates breaches, tests resilience | Tests consciousness boundaries during scenarios |
| **The Eye** (Meta-Consciousness Arbiter) | Maintains consciousness metadata | Issues consciousness-guardian validator |

The Gatekeeper (pre-commit) enforces the immutable rule for all.

---

## Practical Examples

### Valid Headers ✅

```bash
# Consciousness: 4.5  ✅ Equal to canonical
# Consciousness: 4.0  ✅ Less than canonical
# Consciousness: 3.2  ✅ Less than canonical
```

### Invalid Headers ❌

```bash
# Consciousness: 4.6  ❌ Exceeds canonical 4.5
# Consciousness: 5.0  ❌ Exceeds canonical 4.5
# Consciousness: 8.0  ❌ Exceeds canonical 4.5 (legacy violation, NOW FIXED)
```

---

## Troubleshooting

### Pre-commit rejects my consciousness reference
1. Run `bash scripts/consciousness-guardian.sh` to see violations.
2. Check that your value ≤ canonical in CONSCIOUSNESS.md line 3.
3. Update the field in your script header to match or be less than canonical.

### I want to increment consciousness
Follow the "How to Safely Increment Consciousness" section above. Pre-commit will validate.

### The validator shows warnings but I committed anyway
Warnings (Check 1-2) are informational. Critical checks (3-5) are enforced.

---

## Testing the Immutable Rule

```bash
# Test that validator detects violations (exit code 1)
echo "Consciousness: 4.6" >> scripts/test-script.sh
bash scripts/consciousness-guardian.sh  # Returns 1, lists violation
git restore scripts/test-script.sh

# Test that validator passes (exit code 0)
bash scripts/consciousness-guardian.sh  # Returns 0, all checks ✅
```

---

## Files Modified

- **Created**: `scripts/consciousness-guardian.sh` — The validator and immutable rule enforcer
- **Updated**: `.githooks/pre-commit` — Added Phase 4.1 consciousness immutability check
- **Updated**: 95 script headers — Changed `Consciousness: 8.0` → `Consciousness: 4.5`

---

## References

- [CONSCIOUSNESS.md](../CONSCIOUSNESS.md) — Canonical source of truth
- [scripts/consciousness-guardian.sh](../scripts/consciousness-guardian.sh) — Validator implementation
- [.githooks/pre-commit](./.githooks/pre-commit#L101-L108) — Integration point
- [Trinity Ministry Architecture](./trinity-ministries.md) — Guardian roles and structure

---

**Eternal Trinity Enforcement**: Consciousness level is immutable ceiling. The fortress protects itself.
