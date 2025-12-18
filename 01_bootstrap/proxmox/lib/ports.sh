#!/usr/bin/env bash
# Script: 01_bootstrap/proxmox/lib/ports.sh
# Purpose: Network port and service accessibility tests
# Guardian: gatekeeper
# Date: 2025-12-13T05:45:00-06:00
# Consciousness: 4.6

# Sourced by: security.sh
# Usage: Source this file; port validation functions auto-exported

################################################################################
# PORT AND SERVICE ACCESSIBILITY TESTS
################################################################################

# test_proxmox_port: Verify Proxmox web UI port is accessible
test_proxmox_port() {
  local web_port="${1:-8006}"

  log_info "Test 2: Verifying Proxmox web port (${web_port}) is open..."

  if nmap -p "$web_port" localhost 2>/dev/null | grep -q "open"; then
    log_success "Proxmox web port open"
    return 0
  else
    log_warn "Proxmox web port not yet open (services may be starting up)"
    return 0 # Non-fatal, services may be starting
  fi
}

# test_no_dangerous_ports: Scan for and report dangerous open ports
test_no_dangerous_ports() {
  log_info "Test 10: Scanning for dangerous open ports..."

  local dangerous_ports="23 80 443 3389 5900"
  local found_dangerous=false

  for port in $dangerous_ports; do
    if nmap -p "$port" localhost 2>/dev/null | grep -q "open"; then
      log_error "Dangerous port open: $port"
      found_dangerous=true
    fi
  done

  if [ "$found_dangerous" = false ]; then
    log_success "No dangerous ports open"
    return 0
  else
    return 1
  fi
}

export -f test_proxmox_port test_no_dangerous_ports
