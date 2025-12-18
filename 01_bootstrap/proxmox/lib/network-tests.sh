#!/usr/bin/env bash

# Script: 01_bootstrap/proxmox/lib/network.sh
# Purpose: Network connectivity validation (IP, gateway, DNS, identity)
# Guardian: gatekeeper
# Date: 2025-12-13T05:45:00-06:00
# Consciousness: 4.6

# Sourced by: security.sh and common.sh
# Usage: Source this file; network validation functions auto-exported

################################################################################
# NETWORK CONNECTIVITY VALIDATION
################################################################################

# test_hostname_correct: Verify hostname is set correctly
test_hostname_correct() {
  local expected_hostname="${1}"

  log_info "Test 6: Verifying hostname is set correctly..."

  local current_hostname
  current_hostname=$(hostname)

  if [ "$current_hostname" = "$expected_hostname" ]; then
    log_success "Hostname correctly set: $current_hostname"
    return 0
  else
    log_error "Hostname mismatch: expected $expected_hostname, got $current_hostname"
    return 1
  fi
}

# test_static_ip_assigned: Verify static IP is assigned to the system
test_static_ip_assigned() {
  local target_ip="$1"
  local ip_only="${target_ip%/*}"

  log_info "Test 7: Verifying static IP is assigned..."

  if ip addr show | grep -q "inet $ip_only"; then
    log_success "Static IP assigned: $ip_only"
    return 0
  else
    log_error "Static IP not assigned"
    return 1
  fi
}

# test_gateway_reachable: Verify default gateway is reachable
test_gateway_reachable() {
  local gateway_ip="$1"

  log_info "Test 8: Verifying gateway is reachable..."

  if timeout 5 ping -c 1 "$gateway_ip" &>/dev/null; then
    log_success "Gateway reachable: $gateway_ip"
    return 0
  else
    log_error "Gateway not reachable"
    return 1
  fi
}

# test_dns_resolution: Verify DNS resolution is functional
test_dns_resolution() {
  local dns_server="${1:-1.1.1.1}"

  log_info "Test 9: Verifying DNS resolution..."

  if timeout 5 nslookup google.com "$dns_server" &>/dev/null; then
    log_success "DNS resolution working"
    return 0
  else
    log_warn "DNS resolution test failed (may resolve after Carter setup)"
    return 0 # Non-fatal
  fi
}

export -f test_hostname_correct test_static_ip_assigned test_gateway_reachable test_dns_resolution
