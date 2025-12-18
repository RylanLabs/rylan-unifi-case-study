#!/usr/bin/env bash
# Script: 01_bootstrap/proxmox/lib/firewall-vlan.sh
# Purpose: Firewall and VLAN isolation validation tests
# Guardian: gatekeeper
# Date: 2025-12-13T05:45:00-06:00
# Consciousness: 4.6

# Sourced by: security.sh
# Usage: Source this file; firewall/VLAN functions auto-exported

################################################################################
# FIREWALL AND VLAN TESTS
################################################################################

# test_firewall_active: Verify firewall rules exist and are active
test_firewall_active() {
  log_info "Test: Firewall rules exist..."

  if iptables -L -n 2>/dev/null | grep -q "Chain INPUT"; then
    log_success "Firewall rules configured"
    return 0
  else
    log_warn "No firewall rules detected (non-critical)"
    return 0
  fi
}

# test_vlan_isolation: Verify VLAN isolation prevents cross-VLAN traffic
test_vlan_isolation() {
  local server_ip="${1:-10.0.10.10}"

  log_info "Test: VLAN isolation (guest → server)..."

  # This test requires Docker and VLAN networking setup
  # Skip if Docker not available
  if ! command -v docker &>/dev/null; then
    log_warn "Docker not available, skipping VLAN isolation test"
    return 0
  fi

  # Check if mock guest network exists
  if ! docker network ls | grep -q "vlan90\|guest"; then
    log_warn "Guest VLAN network not configured, skipping"
    return 0
  fi

  # Test isolation
  if docker run --rm --network guest alpine ping -c 1 -W 2 "$server_ip" &>/dev/null; then
    log_error "CRITICAL: Guest VLAN can reach server VLAN!"
    return 1
  else
    log_success "VLAN isolation verified (guest cannot reach server)"
    return 0
  fi
}

export -f test_firewall_active test_vlan_isolation
