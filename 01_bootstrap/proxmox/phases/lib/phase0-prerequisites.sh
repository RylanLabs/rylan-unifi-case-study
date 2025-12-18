#!/usr/bin/env bash
# Module: phase0-prerequisites.sh
# Purpose: Pre-flight checks (root, commands, network, metrics)
# Part of: 01_bootstrap/proxmox/phases/phase0-validate.sh refactoring
# Consciousness: 4.6

# PHASE 0: VALIDATION - PREREQUISITES
run_prerequisites_validation() {
  phase_start "0" "Validation - Prerequisites Check"

  record_phase_start "validation"

  # Root check
  log_info "Checking for root privileges..."
  validate_root || fail_with_context 001 "Script requires root" "Run: sudo $0"

  # Required commands
  log_info "Checking for required commands..."
  local required_cmds=(
    "ip"
    "hostnamectl"
    "apt-get"
    "systemctl"
    "git"
    "curl"
    "jq"
    "nmap"
    "ping"
  )

  for cmd in "${required_cmds[@]}"; do
    validate_prerequisite_command "$cmd" ||
      fail_with_context 002 "Missing required command: $cmd" \
        "Install via: apt-get install $cmd"
  done

  log_success "All required commands available"

  # Network connectivity
  log_info "Checking network connectivity..."
  if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    fail_with_context 003 "No internet connectivity" \
      "Check gateway and upstream routing"
  fi
  log_success "Internet connectivity verified"

  # Proxmox not already installed (if strict)
  if command -v pveversion &>/dev/null; then
    log_warn "Proxmox VE appears to be already installed (continuing anyway)"
  fi

  # Initialize metrics
  init_metrics
  record_phase_end "validation"

  log_success "Phase 0: Validation completed successfully"
}

export -f run_prerequisites_validation
