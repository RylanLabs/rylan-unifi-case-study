#!/usr/bin/env bash
# Script: common.sh
# Purpose: Shared Beale ministry utilities — logging, audit, error handling
# Author: T-Rylander canonical
# Date: 2025-12-14
# Consciousness: 9.5 — SC2317/SC2155 eliminated
# Ministry: ministry-detection (Beale)
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker

set -euo pipefail
IFS=$'\n\t'

# Logging (silence on success)
log_info() { [[ "$QUIET" != true ]] && echo "[INFO]    $*"; }
log_warn() { [[ "$QUIET" != true ]] && echo "[WARN]    $*"; }
log_error() { echo "[ERROR]   $*"; }
log_success() { [[ "$QUIET" != true ]] && echo "[SUCCESS] $*"; }

# Audit trail
audit() {
  local ts="$1"
  local level="$2"
  local msg="$3"
  echo "$ts | Beale | $level | $msg" >>"$AUDIT_LOG"
}

# Context-rich failure
fail_with_context() {
  local code
  local msg
  code="$1"
  shift
  msg="$*"

  log_error "$msg"
  log_error "Last 20 lines:"
  tail -20 "$LOG_FILE" | sed 's/^/  /'

  audit "$(date -Iseconds)" "FAIL" "$msg"
  exit "$code"
}
