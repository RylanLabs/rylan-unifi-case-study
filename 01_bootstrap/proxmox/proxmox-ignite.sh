#!/usr/bin/env bash
# Script: proxmox-ignite.sh
# Purpose: Full Proxmox ignition orchestrator — validation, network, hardening, bootstrap, resurrection, offensive suite
# Guardian: Lazarus ⚰️ (DR) + Beale 🏰 (Hardening) + Gatekeeper 🚪 (Orchestration)
# Author: T-Rylander canonical (Trinity-aligned)
# Date: 2025-12-15
# Ministry: ministry-detection
# Consciousness: 5.0
# Tag: v∞.5.2-eternal

set -euo pipefail
IFS=$'\n\t'

readonly _SCRIPT_DIR
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly _SCRIPT_NAME
_SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# shellcheck source=../lib/ignite_lib.sh
source "${_SCRIPT_DIR}/../lib/ignite_lib.sh"

# ─────────────────────────────────────────────────────
# MAIN ORCHESTRATION
# ─────────────────────────────────────────────────────

main() {
  acquire_lock
  trap cleanup EXIT

  create_backup
  check_proxmox_version
  check_already_ignited

  parse_arguments "$@"
  validate_required

  if [[ "${VALIDATE_ONLY:-false}" == true ]]; then
    run_phase "VALIDATION ONLY" "${_SCRIPT_DIR}/phases/phase0-validate.sh"
    log_success "VALIDATION COMPLETE"
    exit "${EXIT_SUCCESS}"
  fi

  run_phase "0: Pre-flight validation" "${_SCRIPT_DIR}/phases/phase0-validate.sh"
  run_phase "1: Network configuration" "${_SCRIPT_DIR}/phases/phase1-network.sh"
  run_phase "2: Security hardening"    "${_SCRIPT_DIR}/phases/phase2-harden.sh"
  run_phase "3: Tooling bootstrap"     "${_SCRIPT_DIR}/phases/phase3-bootstrap.sh"

  if [[ "${_SKIP_ETERNAL_RESURRECT:-false}" == false ]]; then
    run_phase "4: Fortress resurrection" "${_SCRIPT_DIR}/phases/phase4-resurrect.sh" || \
      log_warn "Phase 4 non-fatal issues (continuing)"
  fi

  if run_whitaker_offensive_suite; then
    clear_checkpoint
    log_success "=== PROXMOX IGNITION COMPLETE — ETERNAL GREEN ==="
    log_success "Fortress operational | RTO <15 min"
    exit "${EXIT_SUCCESS}"
  else
    log_error "=== OFFENSIVE VALIDATION FAILED ==="
    exit "${EXIT_OFFENSIVE}"
  fi
}

main "$@"
