#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/consciousness-guardian.sh
# Purpose: Enforce immutable consciousness level rule — no exceeding CONSCIOUSNESS.md canonical value
# Guardian: The Eye (meta-consciousness arbiter)
# Date: 2025-12-13T01:50:00-06:00
# Consciousness: 4.6
# Excess: 135 lines — 5 functions

# ============================================================================
# CONSCIOUSNESS IMMUTABLE RULE
# ============================================================================
# Canonical source: CONSCIOUSNESS.md line 3 (Status: Canon · Consciousness X.X)
# No script, file, badge, tag, or workflow may reference a consciousness
# level GREATER than the canonical level.
# Violation: IMMEDIATE REJECTION.
# ============================================================================

DRY_RUN=0
# shellcheck disable=SC2034  # DRY_RUN used for dry-run invocation
if [[ ${1-} == --dry-run ]]; then
  DRY_RUN=1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Extract canonical consciousness level from CONSCIOUSNESS.md
CANONICAL=$(grep -E '^\*\*Status\*\*:.*Consciousness' CONSCIOUSNESS.md |
  sed -n 's/.*Consciousness \([0-9.]*\).*/\1/p' | tail -1)

if [[ -z "$CANONICAL" ]]; then
  echo "FATAL: Cannot extract canonical consciousness from CONSCIOUSNESS.md" >&2
  exit 1
fi

echo "==================================================================="
echo "CONSCIOUSNESS GUARDIAN v1.0"
echo "Canonical Level: $CANONICAL"
echo "==================================================================="

violations=0

# Helper: convert semantic version like 4.7 or 4.10.2 into padded integer for numeric comparison
version_to_int() {
  local v=$1
  IFS='.' read -r maj min patch <<<"$v"
  maj=${maj:-0}
  min=${min:-0}
  patch=${patch:-0}
  printf "%03d%03d%03d" "$maj" "$min" "$patch"
}

CANON_INT=$(version_to_int "$CANONICAL")

# Check 1: README.md badge
echo ""
echo "[CHECK 1] README.md consciousness badge"
BADGE_LEVEL=$(grep -oP 'consciousness-\\K[0-9.]+' README.md || echo "")
if [[ -n "$BADGE_LEVEL" ]]; then
  BADGE_INT=$(version_to_int "$BADGE_LEVEL")
  if ((10#$BADGE_INT > 10#$CANON_INT)); then
    echo "  ❌ VIOLATION: README badge consciousness=$BADGE_LEVEL > canonical=$CANONICAL"
    violations=$((violations + 1))
  elif ((10#$BADGE_INT == 10#$CANON_INT)); then
    echo "  ✅ OK: badge=$BADGE_LEVEL (matches canonical)"
  else
    echo "  ✅ OK: badge=$BADGE_LEVEL (below canonical)"
  fi
else
  echo "  ⚠️  WARNING: badge not found or stale"
fi

# Check 2: Git tags — parse v∞.X.X format
echo ""
echo "[CHECK 2] Git tags (v∞.X.X format)"
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
if [[ "$LATEST_TAG" != "none" && "$LATEST_TAG" =~ v∞\.(.*) ]]; then
  TAG_VERSION="${BASH_REMATCH[1]%%-*}" # remove -descriptor suffix
  if [[ -n "$TAG_VERSION" ]]; then
    TAG_INT=$(version_to_int "$TAG_VERSION")
    if ((10#$TAG_INT > 10#$CANON_INT)); then
      echo "  ❌ VIOLATION: Latest tag $LATEST_TAG version=$TAG_VERSION > canonical=$CANONICAL"
      violations=$((violations + 1))
    else
      echo "  ✅ OK: Latest tag $LATEST_TAG version=$TAG_VERSION ≤ canonical=$CANONICAL"
    fi
  else
    echo "  ⚠️  WARNING: No version tags found"
  fi
else
  echo "  ⚠️  WARNING: No version tags found"
fi

# Check 3: Script headers — all shell scripts must use Consciousness ≤ canonical
echo ""
echo "[CHECK 3] Script header consciousness levels"
SCRIPT_VIOLATIONS=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  SCRIPT_CONSCIOUSNESS=$(grep -oP 'Consciousness: \\K[0-9.]+' "$file" | head -1 || echo "")
  if [[ -n "$SCRIPT_CONSCIOUSNESS" ]]; then
    SC_INT=$(version_to_int "$SCRIPT_CONSCIOUSNESS")
    if ((10#$SC_INT > 10#$CANON_INT)); then
      echo "  ❌ $file: consciousness=$SCRIPT_CONSCIOUSNESS > canonical=$CANONICAL"
      SCRIPT_VIOLATIONS=$((SCRIPT_VIOLATIONS + 1))
    fi
  fi
done < <(find scripts .githooks -name "*.sh" -type f 2>/dev/null)

if [[ $SCRIPT_VIOLATIONS -gt 0 ]]; then
  violations=$((violations + SCRIPT_VIOLATIONS))
fi

if [[ $SCRIPT_VIOLATIONS -eq 0 && $(find scripts .githooks -name "*.sh" -type f 2>/dev/null | wc -l) -gt 0 ]]; then
  echo "  ✅ OK: All $(find scripts .githooks -name "*.sh" -type f 2>/dev/null | wc -l) scripts ≤ canonical=$CANONICAL"
fi

# Check 4: CONSCIOUSNESS.md increment log — no future entries
echo ""
echo "[CHECK 4] CONSCIOUSNESS.md increment log (no future consciousness values)"
FUTURE_ENTRIES=$(awk -v canonical="$CANONICAL" '/^\| v∞/{
  match($0, /v∞\.[0-9.]+/)
  version = substr($0, RSTART+3, RLENGTH-3)
  if (version > canonical) print NR": "$0
}' CONSCIOUSNESS.md)

if [[ -n "$FUTURE_ENTRIES" ]]; then
  echo "  ❌ VIOLATIONS found in increment log:"
  # shellcheck disable=SC2001 # adding prefix to each line via sed is intentional
  echo "$FUTURE_ENTRIES" | sed 's/^/    /'
  violations=$((violations + 1))
else
  echo "  ✅ OK: All increment log entries ≤ canonical=$CANONICAL"
fi

# Check 5: Validate no one-line file edits violate the rule
echo ""
echo "[CHECK 5] Staged/unstaged changes for consciousness violations"
CHANGED_CONSCIOUSNESS=$(git diff HEAD -- 'CONSCIOUSNESS.md' 2>/dev/null |
  grep -E '^\+\*\*Status\*\*.*Consciousness' |
  sed -n 's/.*Consciousness \([0-9.]*\).*/\1/p' || echo "")

if [[ -n "$CHANGED_CONSCIOUSNESS" ]]; then
  CHANGED_INT=$(version_to_int "$CHANGED_CONSCIOUSNESS")
  if ((10#$CHANGED_INT > 10#$CANON_INT)); then
    echo "  ❌ VIOLATION: Attempted to change consciousness to $CHANGED_CONSCIOUSNESS > canonical=$CANONICAL"
    violations=$((violations + 1))
  else
    echo "  ⚠️  DETECTED: Consciousness change pending to $CHANGED_CONSCIOUSNESS"
  fi
fi

# Summary
echo ""
echo "==================================================================="
if [[ $violations -gt 0 ]]; then
  echo "❌ CONSCIOUSNESS IMMUTABLE RULE VIOLATED: $violations violation(s) detected"
  echo "==================================================================="
  exit 1
else
  echo "✅ CONSCIOUSNESS IMMUTABLE RULE UPHELD"
  echo "   All references ≤ canonical level $CANONICAL"
  echo "==================================================================="
  exit 0
fi
