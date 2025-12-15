#!/usr/bin/env bash
# shellcheck disable=SC1091
# Source helper library extracted to reduce function count
source "${SCRIPT_DIR}/lib/ignite_lib.sh"

  [[ -f "$phase_script" ]] || fail_with_context $EXIT_VALIDATION "Phase script missing: $phase_script"

  log_info "[PHASE] $phase_name starting"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would execute: bash $phase_script"
    bash "$phase_script" --dry-run 2>/dev/null || true
    return 0
  fi

  if bash "$phase_script" >"$output_file" 2>&1; then
    log_success "$phase_name PASSED"
    save_checkpoint "$phase_name"
    return 0
  else
    local rc=$?
    log_error "$phase_name FAILED (exit $rc)"
    log_error "Full output: $output_file"
    log_error "Last $LOG_TAIL_LINES lines:"
    tail -n "$LOG_TAIL_LINES" "$output_file" | sed 's/^/  /'
    auto_rollback
    fail_with_context $rc "Phase $phase_name failed"
  fi
}

# =============================================================================
# PILLAR 2 + 6: DRY-RUN + DOCUMENTATION
# =============================================================================

print_usage() {
  cat <<EOF

Usage: sudo $SCRIPT_NAME [OPTIONS]

EXAMPLES:
  # Full production ignition
  sudo $SCRIPT_NAME --hostname rylan-dc --ip 10.0.10.10/26 --gateway 10.0.10.1

  # Dry-run preview
  sudo $SCRIPT_NAME --hostname test --ip 10.0.10.20/26 --gateway 10.0.10.1 --dry-run

  # Validation only
  sudo $SCRIPT_NAME --hostname rylan-dc --ip 10.0.10.10/26 --gateway 10.0.10.1 --validate-only

  # Force re-ignition
  sudo $SCRIPT_NAME --hostname rylan-dc --ip 10.0.10.10/26 --gateway 10.0.10.1 --force

EXIT CODES:
  0 = Success
  1 = Validation failure
  2 = Network configuration failure
  3 = Security hardening failure
  5 = Backup/recovery failure
  7 = Offensive validation failure

TROUBLESHOOTING:
  • Logs:           tail -f $LOG_FILE
  • All logs:       ls -la $LOG_DIR
  • Manual rollback: cp -a $BACKUP_DIR/* / && reboot
  • Stuck lock:     rm -f $LOCK_FILE (verify no PID running)
  • Resume:         Script auto-resumes from checkpoint

EOF
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --hostname)           HOSTNAME="$2"; shift 2 ;;
      --ip)                 TARGET_IP="$2"; shift 2 ;;
      --gateway)            GATEWAY_IP="$2"; shift 2 ;;
      --ssh-key-source)     SSH_KEY_SOURCE="$2"; shift 2 ;;
      --dns-primary)        PRIMARY_DNS="$2"; shift 2 ;;
      --dns-secondary)      FALLBACK_DNS="$2"; shift 2 ;;
      --dry-run)            DRY_RUN=true; shift ;;
      --validate-only)      VALIDATE_ONLY=true; shift ;;
      --skip-eternal-resurrect) SKIP_ETERNAL_RESURRECT=true; shift ;;
      --force)              FORCE=true; shift ;;
      --json-logs)          JSON_LOGS=true; shift ;;
      *) log_error "Unknown argument: $1"; print_usage; exit $EXIT_VALIDATION ;;
    esac
  done
}

validate_required() {
  [[ -n "$HOSTNAME" ]]   || fail_with_context $EXIT_VALIDATION "Missing --hostname"
  [[ -n "$TARGET_IP" ]]  || fail_with_context $EXIT_VALIDATION "Missing --ip"
  [[ -n "$GATEWAY_IP" ]] || fail_with_context $EXIT_VALIDATION "Missing --gateway"

  [[ "$TARGET_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]{1,2}$ ]] ||
    fail_with_context $EXIT_VALIDATION "Invalid IP/CIDR: $TARGET_IP"
  [[ "$GATEWAY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    fail_with_context $EXIT_VALIDATION "Invalid gateway: $GATEWAY_IP"
}

# =============================================================================
# MAIN ORCHESTRATION (Leo's corrected order)
# =============================================================================

main() {
  print_rylanlabs_banner

  log_info "=== PROXMOX IGNITE v3 — A+ PRODUCTION HOMOGENIZED ==="
  log_info "Log file: $LOG_FILE"
  log_info "Dry-run: $DRY_RUN | Validate-only: $VALIDATE_ONLY | Force: $FORCE"

  acquire_lock
  create_backup
  check_proxmox_version
  check_already_ignited

  parse_arguments "$@"
  validate_required

  if [[ "$VALIDATE_ONLY" == true ]]; then
    run_phase "VALIDATION ONLY" "${SCRIPT_DIR}/phases/phase0-validate.sh"
    log_success "VALIDATION COMPLETE"
    exit $EXIT_SUCCESS
  fi

  # Resume logic
  if [[ -f "$CHECKPOINT_FILE" ]]; then
    local last_phase;
    last_phase=$(cat "$CHECKPOINT_FILE")
    log_info "Resuming from checkpoint: $last_phase"
  fi

  # Phase execution (skip completed via checkpoint or idempotency in phases)
  run_phase "0: Pre-flight validation" "${SCRIPT_DIR}/phases/phase0-validate.sh"
  run_phase "1: Network configuration" "${SCRIPT_DIR}/phases/phase1-network.sh"
  run_phase "2: Security hardening"    "${SCRIPT_DIR}/phases/phase2-harden.sh"
  run_phase "3: Tooling bootstrap"     "${SCRIPT_DIR}/phases/phase3-bootstrap.sh"

  if [[ "$SKIP_ETERNAL_RESURRECT" == false ]]; then
    run_phase "4: Fortress resurrection" "${SCRIPT_DIR}/phases/phase4-resurrect.sh" ||
      log_warn "Phase 4 non-fatal issues (continuing)"
  fi

  if run_whitaker_offensive_suite; then
    clear_checkpoint
    log_success "=== PROXMOX IGNITION COMPLETE — ETERNAL GREEN ==="
    log_success "Fortress operational | Marker: $MARKER_FILE | RTO <15 min"
    exit $EXIT_SUCCESS
  else
    log_error "=== OFFENSIVE VALIDATION FAILED ==="
    exit $EXIT_OFFENSIVE
  fi
}

# =============================================================================
# LIBRARY SOURCING (after all functions defined)
# =============================================================================

for lib in common.sh metrics.sh security.sh; do
  source "${SCRIPT_DIR}/lib/${lib}" || fail_with_context $EXIT_VALIDATION "Failed to source lib/${lib}"
done

# =============================================================================
# EXECUTE (must be last)
# =============================================================================

main "$@"
