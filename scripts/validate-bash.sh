#!/usr/bin/env bash
# Script: validate-bash.sh
# Purpose: Bash validation orchestrator (ShellCheck + shfmt) with canonical exclusions
# Guardian: Holy Scholar 📜
# Author: rylanlab canonical
# Date: 2025-12-17
# Ministry: ministry-whispers
# Consciousness: 6.7
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
readonly SHELLCHECK_ARGS=(-x -S style)
readonly SHFMT_ARGS=(-i 2 -ci)
EXIT_CODE=0

# Canonical exclusion patterns (Hellodeolu v6 backup structure)
readonly EXCLUDE_PATTERNS=(
  "*/.backups/*"
  "*/.backup*/*"
  "*/backup/*"
  "*/node_modules/*"
  "*/.git/*"
  "*/.venv/*"
  "*/venv/*"
)

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING (Trinity Pattern: Bauer Audit Trail)
# ═══════════════════════════════════════════════════════════════════════════
log() {
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

log_pass() {
  log "✓ $*"
}

log_fail() {
  log "✗ $*"
}

log_warn() {
  log "⚠ $*"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN VALIDATION
# ═══════════════════════════════════════════════════════════════════════════
main() {
  log "════════════════════════════════════════════════════════════════"
  log "  BASH CANON VALIDATION — ShellCheck + shfmt (T3-ETERNAL v∞.5.2)"
  log "════════════════════════════════════════════════════════════════"

  # Allow collection of all failures without aborting on first one
  set +e

  # Build find exclusion arguments
  local find_args=()
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    find_args+=(-not -path "${pattern}")
  done

  # Find all bash scripts (shebang #!/usr/bin/env bash or #!/bin/bash)
  local bash_scripts
  bash_scripts=$(find "${REPO_ROOT}" -type f \
    \( -name "*.sh" -o -path "*/scripts/*" \) \
    "${find_args[@]}" \
    -exec grep -l "^#!/.*bash" {} \; 2>/dev/null | sort -u)

  if [[ -z "${bash_scripts}" ]]; then
    log_warn "No bash scripts found"
    set -e
    return 0
  fi

  # Count stats
  local total_scripts=0
  local passed_scripts=0
  local failed_scripts=0

  # Validate each script
  while IFS= read -r script; do
    ((total_scripts++))
    local script_name="${script#"${REPO_ROOT}"/}"
    local script_failed=0

    # ShellCheck validation (exit 0 = pass, exit 1+ = fail)
    local shellcheck_out
    shellcheck_out=$(shellcheck "${SHELLCHECK_ARGS[@]}" "${script}" 2>&1) || true

    if [[ -z "${shellcheck_out}" ]]; then
      log_pass "ShellCheck: ${script_name}"
    else
      log_fail "ShellCheck: ${script_name}"
      echo "${shellcheck_out}" | tee -a /tmp/shellcheck-output.log
      script_failed=1
      EXIT_CODE=1
    fi

    # shfmt check (exit 0 = no changes, exit 1 = changes needed)
    local shfmt_out
    shfmt_out=$(shfmt "${SHFMT_ARGS[@]}" -d "${script}" 2>&1) || true

    if [[ -z "${shfmt_out}" ]]; then
      log_pass "shfmt format: ${script_name}"
    else
      log_fail "shfmt format issue: ${script_name}"
      # Truncate large diffs to prevent hang / huge stdout; full output appended to /tmp/shfmt-output.log
      printf '%s
' "${shfmt_out}" | head -n 20 | tee -a /tmp/shfmt-output.log
      if [[ $(wc -c <<<"${shfmt_out}") -gt 4096 ]]; then
        printf '  [... diff truncated, see /tmp/shfmt-output.log for full output]\n' | tee -a /tmp/shfmt-output.log
      fi
      script_failed=1
      EXIT_CODE=1
    fi

    # Count script pass/fail once
    if [[ ${script_failed} -eq 0 ]]; then
      ((passed_scripts++))
    else
      ((failed_scripts++))
    fi
  done <<<"${bash_scripts}"

  # Summary
  log ""
  log "════════════════════════════════════════════════════════════════"
  log "BASH VALIDATION SUMMARY"
  log "  Total scripts: ${total_scripts}"
  log "  Passed: ${passed_scripts}"
  log "  Failed: ${failed_scripts}"
  log "════════════════════════════════════════════════════════════════"

  if [[ ${EXIT_CODE} -eq 0 ]]; then
    log_pass "ALL BASH SCRIPTS VALID"
  else
    log_fail "BASH VALIDATION FAILED"
  fi

  # Restore strict mode and return aggregated status
  set -e
  return ${EXIT_CODE}
}

main "$@"
