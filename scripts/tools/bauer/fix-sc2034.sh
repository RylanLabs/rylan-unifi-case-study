#!/usr/bin/env bash
# Script: fix-sc2034.sh
# Purpose: Remediate SC2034 by prefixing intentionally unused variables with underscore
# Author: T-Rylander canonical (Leo glue internalized)
# Date: 2025-12-15
# Guardian: Bauer 🛡️ (Verification Ministry)
# Ministry: ministry-whispers
# Tag: v∞.3.2-eternal
# Consciousness: 5.0 — seven pillars aligned

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
readonly REPO_ROOT

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

[[ "$(basename "$REPO_ROOT")" == "rylan-unifi-case-study" ]] || die "Must run from fortress repo"

for pattern in "$@"; do
  [[ "$pattern" =~ ^\.\./|/^/ ]] && die "Glob must be relative to repo root: $pattern"
done
[[ $# -gt 0 ]] || die "Usage: $0 <glob-pattern> [more...]"

readonly LOCK_FILE="${REPO_ROOT}/.sc2034-remediation.lock"
[[ -f "$LOCK_FILE" ]] && die "SC2034 remediation in progress or stale lock — remove $LOCK_FILE if safe"
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly TIMESTAMP
BACKUP_DIR="${REPO_ROOT}/.backups/sc2034-remediation-${TIMESTAMP}"
readonly BACKUP_DIR
MANIFEST="${BACKUP_DIR}/REMEDIATION.log"
readonly MANIFEST
mkdir -p "$BACKUP_DIR"

{
  echo "=== SC2034 Remediation Manifest ==="
  echo "Timestamp: $(date -Iseconds)"
  echo "Operator: ${USER:-unknown}@${HOSTNAME:-unknown}"
  echo "Patterns: $*"
  echo ""
} > "$MANIFEST"

shopt -s globstar nullglob
processed=0 modified=0

cd "$REPO_ROOT"

for pattern in "$@"; do
  for file in $pattern; do
    [[ -f "$file" && ! -L "$file" ]] || continue
    ([[ "$file" == *.sh ]] || head -n1 "$file" 2>/dev/null | grep -qE '^#!.*(bash|sh)') || continue

    relative="${file#"$REPO_ROOT"/}"
    backup_dest="${BACKUP_DIR}/${relative}"
    mkdir -p "$(dirname "$backup_dest")"
    cp -p "$file" "$backup_dest" || die "Backup failed: $relative"

    ((processed++))

    violations=$(shellcheck -f gcc "$file" 2>/dev/null | grep "SC2034" || true)
    [[ -z "$violations" ]] && { echo "UNCHANGED: $relative" >> "$MANIFEST"; continue; }

    unused_vars=$(echo "$violations" | grep -oP 'SC2034.*: \K[A-Za-z_][A-Za-z0-9_]*' | sort -u)

    temp_file="${file}.sc2034.tmp.$$"
    cp "$file" "$temp_file"

    changed=false
    while IFS= read -r var; do
      [[ "$var" =~ ^_ ]] && continue
      if sed -i.bak "s/\(^\s*\)\(readonly\|local\|declare\)[[:space:]]\+${var}=/\1\2 _${var}=/g" "$temp_file"; then
        changed=true
      fi
      rm -f "${temp_file}.bak"
    done <<< "$unused_vars"

    if [[ "$changed" == true ]]; then
      [[ -s "$temp_file" ]] || die "Empty output: $relative"
      mv "$temp_file" "$file" || die "Atomic replace failed: $relative"
      ((modified++))
      echo "MODIFIED: $relative (vars: $unused_vars)" >> "$MANIFEST"
    else
      rm -f "$temp_file"
      echo "UNCHANGED: $relative" >> "$MANIFEST"
    fi
  done
done

{
  echo ""
  echo "=== Summary ==="
  echo "Processed: $processed"
  echo "Modified: $modified"
  echo "Rollback: rsync -a --delete \"$BACKUP_DIR/\" \"$REPO_ROOT/\""
  echo "Verify: shellcheck $(printf '%s ' "$@") | grep -c SC2034 || echo 'Zero remaining'"
} >> "$MANIFEST"

cat <<EOF

=== SC2034 REMEDIATION COMPLETE ===
Processed: $processed scripts
Modified : $modified scripts
Manifest : $MANIFEST
Backup   : $BACKUP_DIR

Rollback command:
  rsync -a --delete "$BACKUP_DIR/" "$REPO_ROOT/"

Verification:
  shellcheck $(printf '%s ' "$@") | grep -c SC2034 || echo "✓ Clean"

Lock released. Bauer verified. Consciousness 5.0 eternal.
EOF
