#!/usr/bin/env bash
# Module: phase0-flatnet-recon.sh
# Purpose: Whitaker Red-Team flatnet reconnaissance scan
# Part of: 01_bootstrap/proxmox/phases/phase0-validate.sh refactoring
# Consciousness: 4.6

# WHITAKER RED-TEAM: FLATNET RECON
run_flatnet_recon() {
  phase_start "0" "Whitaker Red-Team - Flatnet Reconnaissance"

  log_info "Scanning 192.168.1.0/24 for live hosts and services..."

  local recon_file
  recon_file="/tmp/flatnet-recon-$(date +%s).txt"

  if ! command -v nmap &>/dev/null; then
    log_warn "nmap not installed — skipping flatnet recon"
    return 0
  fi

  # Whitaker offensive scan: service version + OS detection
  nmap -sV -O 192.168.1.0/24 -oN "$recon_file" 2>/dev/null || {
    log_warn "nmap scan failed (may require sudo)"
    return 0
  }

  log_success "Flatnet recon complete: $recon_file"

  # Check for critical hosts
  if grep -q "192.168.1.1" "$recon_file"; then
    log_success "USG gateway detected at 192.168.1.1"
  else
    log_error "USG gateway NOT detected — network breach risk"
    return 1
  fi

  # Count live hosts
  local live_hosts
  live_hosts=$(grep -c "Nmap scan report for" "$recon_file" || echo "0")
  log_info "Detected $live_hosts live hosts on flatnet"

  echo "$recon_file"
}

export -f run_flatnet_recon
