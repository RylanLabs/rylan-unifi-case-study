#!/usr/bin/env bash
# Script: proxmox-ignite-quickstart.sh
# Purpose: Interactive junior-proof wrapper + non-interactive mode for proxmox-ignite.sh
# Author: T-Rylander canonical
# Date: 2025-12-13
# Source helper library extracted to reduce function count
source "${SCRIPT_DIR}/lib/quickstart_lib.sh"

Non-Interactive Examples:
  sudo $SCRIPT_NAME --hostname rylan-dc --ip 10.0.10.10/26 --gateway 10.0.10.1 --ssh-key ~/.ssh/id_ed25519.pub

Options:
  --hostname NAME           Proxmox hostname
  --ip IP/CIDR              IP with CIDR (e.g. 10.0.10.10/26)
  --gateway IP              Gateway IP
  --ssh-key PATH            Path to public key
  --dry-run                 Preview only
  --non-interactive         Use defaults (CI mode)
  --force                   Override already-ignited check
  -h, --help                Show this help

Exit Codes:
  0 = Success / Cancelled
  1 = Validation failure
  4 = Prerequisites missing

Logs: $LOG_DIR
Documentation: https://github.com/T-Rylander/rylan-unifi-case-study

EOF
}

parse_cli_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --hostname)           HOSTNAME="$2"; shift 2 ;;
      --ip)                 TARGET_IP="$2"; shift 2 ;;
      --gateway)            GATEWAY_IP="$2"; shift 2 ;;
      --ssh-key)            SSH_KEY_PATH="$2"; shift 2 ;;
      --dry-run)            DRY_RUN=true; shift ;;
      --non-interactive)    NON_INTERACTIVE=true; shift ;;
      --force)              FORCE=true; shift ;;
      -h|--help)            print_usage; exit $EXIT_SUCCESS ;;
      *) log_error "Unknown argument: $1"; print_usage; exit $EXIT_VALIDATION ;;
    esac
  done
}

# =============================================================================
# FAILURE RECOVERY GUIDES
# =============================================================================

print_failure_recovery() {
  cat <<'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  ⚠️  IGNITION FAILED — RECOVERY STEPS                                        ║
║                                                                              ║
║  1. Review logs:                                                             ║
║     tail -100 /opt/fortress/logs/proxmox-quickstart-*.log                    ║
║     tail -100 /opt/fortress/logs/proxmox-ignite-*.log                        ║
║                                                                              ║
║  2. Check network:                                                           ║
║     ping <gateway>                                                           ║
║     ip addr show                                                             ║
║                                                                              ║
║  3. Rollback (if partial changes applied):                                   ║
║     Consult core backup in /opt/fortress/.backups/                           ║
║                                                                              ║
║  4. Retry with last config:                                                  ║
║     sudo ./proxmox-ignite-quickstart.sh                                      ║
║     (will offer to load previous settings)                                   ║
║                                                                              ║
║  5. Get help:                                                                ║
║     https://github.com/T-Rylander/rylan-unifi-case-study/issues              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
}

print_success_guide() {
  cat <<'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  ✅ IGNITION SUCCESSFUL — WELCOME TO THE FORTRESS                             ║
║                                                                              ║
║  Next Steps (Junior-Proof):                                                   ║
║                                                                              ║
║  1. SSH Access:                                                              ║
║     ssh -i ~/.ssh/id_ed25519 root@rylan-dc                                   ║
║                                                                              ║
║  2. Proxmox Web UI:                                                          ║
║     https://rylan-dc:8006 (accept self-signed cert)                         ║
║                                                                              ║
║  3. Validate Fortress:                                                       ║
║     cd /opt/fortress && ./validate-eternal.sh                                ║
║                                                                              ║
║  4. Review Logs:                                                             ║
║     tail -f /opt/fortress/logs/proxmox-ignite-*.log                          ║
║                                                                              ║
║  Session ID: SESSION_ID_PLACEHOLDER                                          ║
║  The fortress is operational. RTO <15 min achieved.                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
  sed "s/SESSION_ID_PLACEHOLDER/$SESSION_ID/" # inline replace
}

# =============================================================================
# MAIN ORCHESTRATION
# =============================================================================

main() {
  print_rylanlabs_banner

  log_info "=== PROXMOX QUICKSTART v6.5 — A+ SACRED GLUE MANIFESTED ==="
  log_info "Session ID: $SESSION_ID"
  log_info "Log: $LOG_FILE"

  validate_prerequisites

  parse_cli_arguments "$@"

  if [[ "$NON_INTERACTIVE" == false ]]; then
    load_previous_configuration || true

    HOSTNAME=$(prompt_input "Hostname" "${HOSTNAME:-rylan-dc}" "rylan-dc, proxmox-01")
    HOSTNAME=$(sanitize_hostname "$HOSTNAME")
    log_audit "INPUT" "hostname=$HOSTNAME"

    TARGET_IP=$(prompt_input "IP Address (with CIDR)" "${TARGET_IP:-10.0.10.10/26}" "10.0.10.20/26")
    log_audit "INPUT" "ip=$TARGET_IP"

    GATEWAY_IP=$(prompt_input "Gateway IP" "${GATEWAY_IP:-10.0.10.1}" "10.0.10.1")
    log_audit "INPUT" "gateway=$GATEWAY_IP"

    local default_key="${HOME}/.ssh/id_ed25519.pub"
    SSH_KEY_PATH=$(prompt_input "SSH Public Key Path" "${SSH_KEY_PATH:-$default_key}")
  fi

  # Final validations (CLI or interactive)
  [[ -n "$HOSTNAME" && -n "$TARGET_IP" && -n "$GATEWAY_IP" && -n "$SSH_KEY_PATH" ]] ||
    fail_with_context $EXIT_VALIDATION "All parameters required"

  validate_network_input
  validate_ssh_key "$SSH_KEY_PATH"
  check_already_ignited

  print_configuration_summary
  confirm_deployment

  save_configuration
  log_audit "CONFIGURATION" "final hostname=$HOSTNAME ip=$TARGET_IP gateway=$GATEWAY_IP ssh_key=$SSH_KEY_PATH"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would execute core ignition with above configuration"
    log_success "DRY-RUN COMPLETE"
    exit $EXIT_SUCCESS
  fi

  log_info "Executing core orchestrator (timeout $IGNITION_TIMEOUT seconds)..."

  local core_output;
  core_output=$(mktemp)
  trap "rm -f $core_output" RETURN

  if timeout "$IGNITION_TIMEOUT" bash "$IGNITE_SCRIPT" \
    --hostname "$HOSTNAME" \
    --ip "$TARGET_IP" \
    --gateway "$GATEWAY_IP" \
    --ssh-key-source "file:$SSH_KEY_PATH" \
    --session-id "$SESSION_ID" \
    2>&1 | tee "$core_output"; then

    log_success "Core ignition completed successfully"
    print_success_guide
    exit $EXIT_SUCCESS
  else
    local rc=$?
    if [[ $rc -eq 124 ]]; then
      log_error "Ignition timed out after $IGNITION_TIMEOUT seconds"
    else
      log_error "Core ignition failed with exit code $rc"
    fi

    # Context parsing
    if grep -qi "validation failed" "$core_output"; then
      log_error "Pre-flight validation failed — check network/DNS"
    elif grep -qi "ssh" "$core_output"; then
      log_error "SSH configuration issue — verify key permissions"
    fi

    log_error "Full core output saved to $core_output"
    fail_with_context $rc "Ignition failed"
  fi
}

main "$@"
