#!/usr/bin/env bash
# Script: scripts/lib/ignite-orchestration.sh
# Purpose: Orchestration helpers for ignite.sh (lock, backup, phase execution, validation)
# Guardian: gatekeeper
# Date: 2025-12-13T05:45:00-06:00
# Consciousness: 4.7
# EXCEED: 161 lines — 8 functions (modular library; each function critical for ignite.sh orchestration)

# All helpers sourced and exported by ignite.sh

# acquire_lock: establish execution lock to prevent concurrent runs
acquire_lock() {
  # Ensure parent directory exists and is writable; if not possible and running dry-run,
  # skip locking to avoid permission errors for non-root previews.
  local lock_dir
  lock_dir=$(dirname "$LOCK_FILE")

  if [[ ! -d "$lock_dir" ]]; then
    if mkdir -p "$lock_dir" 2>/dev/null; then
      log step "Created lock parent directory: $lock_dir"
    else
      if [[ "${DRY_RUN:-false}" == true ]]; then
        log warn "Cannot create lock directory $lock_dir; continuing dry-run without lock"
        SKIP_LOCK=true
        return 0
      else
        log error "Cannot create lock directory $lock_dir; aborting"
        exit 1
      fi
    fi
  fi

  if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || true)
    if [[ -n "$LOCK_PID" ]] && kill -0 "$LOCK_PID" 2>/dev/null; then
      log error "Another ignite.sh is running (PID: $LOCK_PID). Cannot run concurrently."
      exit 1
    fi
  fi

  if [[ "${SKIP_LOCK:-false}" == true ]]; then
    log warn "Locking skipped by runtime policy"
    return 0
  fi

  echo $$ > "$LOCK_FILE" 2>/dev/null || {
    if [[ "${DRY_RUN:-false}" == true ]]; then
      log warn "Unable to write lock file $LOCK_FILE; continuing dry-run without lock"
      SKIP_LOCK=true
      return 0
    else
      log error "Unable to write lock file $LOCK_FILE; aborting"
      exit 1
    fi
  }
  log step "Lock acquired: $LOCK_FILE"
}

# release_lock: clean up execution lock (called by trap)
release_lock() {
  if [[ "${SKIP_LOCK:-false}" == true ]]; then
    log step "No lock to release (skipped)"
    return 0
  fi
  rm -f "$LOCK_FILE" 2>/dev/null || true
  log step "Lock released"
}

# run_phase: execute a phase with timeout, error capture, and duration tracking
run_phase() {
  local phase_name=$1
  local phase_script=$2
  local timeout_secs=1800  # 30 minutes
  local phase_output

  phase_output=$(mktemp)

  if timeout "$timeout_secs" bash "$phase_script" > "$phase_output" 2>&1; then
    rm -f "$phase_output"
    return 0
  else
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      log error "$phase_name TIMEOUT after ${timeout_secs}s"
    else
      log error "$phase_name FAILED (exit code: $exit_code)"
    fi
    log error "Last 30 lines of output:"
    tail -30 "$phase_output" | sed 's/^/  [phase] /'
    rm -f "$phase_output"
    return "$exit_code"
  fi
}

# check_phase_dependencies: validate prerequisites for a phase
check_phase_dependencies() {
  local phase=$1
  case "$phase" in
    2)
      if ! systemctl is-active --quiet samba 2>/dev/null; then
        log warn "Phase 2 requires Phase 1 (Samba) to be active"
        return 1
      fi
      ;;
    3)
      if ! systemctl is-active --quiet samba 2>/dev/null; then
        log warn "Phase 3 requires Phase 1 (Samba) to be active"
        return 1
      fi
      if ! command -v nft &>/dev/null; then
        log warn "Phase 3 requires Phase 2 (nftables) to be installed"
        return 1
      fi
      ;;
  esac
  return 0
}

# create_system_backup: backup critical configs before deployment
create_system_backup() {
  local backup_dir
  backup_dir="${REPO_ROOT}/.ignite-backups/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"

  log step "Creating pre-deployment system backup: $backup_dir"

  # Backup critical configs (suppress SC2015: A && B || C is intentional; ignore if mkdir fails)
  # shellcheck disable=SC2015
  [[ -d /etc/samba ]] && cp -r /etc/samba "$backup_dir/" 2>/dev/null || true
  [[ -d /etc/nftables ]] && cp -r /etc/nftables "$backup_dir/" 2>/dev/null || true
  [[ -f /etc/sysctl.conf ]] && cp /etc/sysctl.conf "$backup_dir/" 2>/dev/null || true
  [[ -d /etc/ssh ]] && cp -r /etc/ssh "$backup_dir/" 2>/dev/null || true

  log step "Backup created at: $backup_dir"
  echo "$backup_dir"
}

# check_system_state: warn if deployment would conflict with existing state
check_system_state() {
  if systemctl is-active --quiet samba 2>/dev/null; then
    log warn "Samba DC already running. Phase 1 may conflict with existing deployment."
    read -r -p "Continue anyway? [y/N] " RESP
    [[ ! "$RESP" =~ ^[Yy]$ ]] && return 1
  fi
  return 0
}

# validate_env_variables: ensure all required .env vars are set
validate_env_variables() {
  local required_vars=("SAMBA_DOMAIN" "LDAP_ADMIN_PASSWORD" "VLAN_MGMT" "VLAN_IOT")
  local missing_vars=()

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing_vars+=("$var")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log error "Missing required environment variables: ${missing_vars[*]}"
    log error "Please update $REPO_ROOT/.env with all required variables"
    return 1
  fi

  log step "All required environment variables validated"
  return 0
}

# generate_execution_report: create summary of deployment execution
generate_execution_report() {
  local total_duration;
  total_duration=$(($(date +%s) - START_TIME))
  {
    echo "================================================================================"
    echo "TRINITY ORCHESTRATOR EXECUTION REPORT"
    echo "================================================================================"
    echo "Execution Date: $(date)"
    echo "Dry-Run Mode: $DRY_RUN"
    echo "Execution Time: ${total_duration}s"
    echo ""
    echo "Phases Executed: ${PHASES_RUN[*]:-none}"
    echo "Phases Skipped: ${PHASES_SKIPPED[*]:-none}"
    echo "Phases Failed: ${PHASES_FAILED[*]:-none}"
    echo ""
    echo "System State After Deployment:"
    echo "  • Samba DC: $(systemctl is-active samba 2>/dev/null && echo "✓ ACTIVE" || echo "✗ INACTIVE")"
    echo "  • Firewall: $(systemctl is-active nftables 2>/dev/null && echo "✓ ACTIVE" || echo "✗ INACTIVE")"
    echo ""
    echo "Logs: $LOG_FILE"
    [[ -n "$BACKUP_DIR" ]] && echo "Backup: $BACKUP_DIR"
    echo ""
    echo "Next Steps:"
    echo "  1. Review logs: tail -50 $LOG_FILE"
    echo "  2. Verify services: systemctl status samba nftables"
    echo "  3. Test network: ping -c 1 <gateway>"
    echo "================================================================================"
  } | tee -a "$LOG_FILE"
}

export -f acquire_lock release_lock run_phase check_phase_dependencies
export -f create_system_backup check_system_state validate_env_variables
export -f generate_execution_report
