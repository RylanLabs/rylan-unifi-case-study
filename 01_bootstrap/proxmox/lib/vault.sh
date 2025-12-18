#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/vault.sh
# Purpose: Backup and rollback mechanisms for safe configuration changes
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6
# EXCEED: 60 lines — 4 functions

# Sourced by: common.sh
# Usage: Source this file; backup/rollback functions auto-exported
# Note: Sets ERR trap for automatic rollback handling

################################################################################
# BACKUP & ROLLBACK MECHANISM
################################################################################

# backup_config: Create timestamped backup of config file
backup_config() {
  local file="$1"

  if [ ! -f "$file" ]; then
    return 0
  fi

  mkdir -p "${BACKUP_DIR}"

  local backup_name
  backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
  cp -a "$file" "${BACKUP_DIR}/${backup_name}"

  log_info "Backed up: $file → ${backup_name}"
  touch "${ROLLBACK_MARKER}"
}

# rollback_all: Restore all backed-up configuration files
rollback_all() {
  if [ ! -f "${ROLLBACK_MARKER}" ]; then
    log_error "No rollback available"
    return 1
  fi

  log_warn "ROLLING BACK ALL CHANGES"

  # Restore all .bak files (reverse chronological order)
  find "${BACKUP_DIR}" -name "*.bak" -type f -printf '%T@\t%p\n' |
    sort -rn | cut -f2 | while read -r backup; do
    local original
    original="${backup%.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9].bak}"
    if [ -f "$backup" ]; then
      cp -a "$backup" "$original"
      log_info "Restored: $(basename "$original")"
    fi
  done

  # Restart affected services
  systemctl restart sshd networking pveproxy || true

  log_success "Rollback complete"
}

# rollback_prompt: Handle failed commands with interactive rollback option
rollback_prompt() {
  local line_no="${1:-0}"
  log_error "IGNITION FAILED at line ${line_no}"

  if [ -f "${ROLLBACK_MARKER}" ]; then
    read -p "Rollback changes? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rollback_all
    fi
  fi

  exit 1
}

# fail_with_context: Rich error message with remediation and automatic rollback
fail_with_context() {
  local error_code="$1"
  local error_msg="$2"
  local remediation="${3:-}"

  echo ""
  log_error "FAILURE [ERR-${error_code}]: ${error_msg}"

  if [ -n "$remediation" ]; then
    echo -e "${YELLOW}Remediation:${NC} ${remediation}"
  fi

  echo ""
  echo -e "${BLUE}Logs:${NC} ${LOG_FILE}"
  echo -e "${BLUE}Support:${NC} https://github.com/T-Rylander/rylan-unifi-case-study/issues"
  echo ""

  exit "$error_code"
}

export -f backup_config rollback_all rollback_prompt fail_with_context

# Set up automatic rollback on error (trap must be set in main script after sourcing)
# Not set here to allow sourcing this library without triggering trap during initialization
