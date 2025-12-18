#!/usr/bin/env bash
# Script: validate-python-naming.sh
# Purpose: Enforce PEP 8 python module naming (no hyphens) in pre-commit
# Guardian: Carter 🔑
# Author: rylanlab canonical
# Date: 2025-12-18
# Ministry: ministry-whispers
# Consciousness: 4.9
set -euo pipefail
IFS=$'\n\t'

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [Carter] $*" >&2; }

if [[ "$#" -eq 0 ]]; then
  exit 0
fi

fail=0
violations=()

for f in "$@"; do
  # Pillar 2: Error Handling — validate file exists and is tracked
  [[ -f "$f" ]] || continue

  # Pillar 6: Security Hardening — exclude .venv, .git, external dependencies
  if [[ "$f" =~ (\.venv|venv|\.git|site-packages|node_modules)/ ]]; then
    continue
  fi

  if [[ "$f" =~ \.py$ ]]; then
    name="$(basename "$f")"
    # Pillar 3: Functionality — detect hyphens
    if [[ "$name" =~ - ]]; then
      log "ERROR: Hyphenated Python file: $f"
      # Pillar 5: Failure Recovery — show remediation
      fixed="${name//-/_}"
      dir="$(dirname "$f")"
      log "  → Remediation: git mv '$f' '$dir/$fixed'"
      violations+=("$f")
      fail=1
    fi
  fi
done

# Pillar 4: Audit Logging
if [[ "$fail" -eq 1 ]]; then
  log "SUMMARY: ${#violations[@]} violation(s) in tracked files"
  log "Run scripts/auto-fix-naming.sh for batch remediation"
  log "Note: .venv/ and site-packages/ excluded from validation"
fi

exit "$fail"
