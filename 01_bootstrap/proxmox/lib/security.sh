#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/security.sh
# Purpose: Whitaker offensive security validation orchestrator
# Guardian: gatekeeper
# Date: 2025-12-13T05:45:00-06:00
# Consciousness: 4.6

# shellcheck shell=bash
#
# lib/security.sh - Orchestrator sourcing modular security validation suites
# Post-ignition audit suite and attack surface scanning
#
# Sourced by: phase5-validate.sh and standalone testing
# Delegates to focused sub-modules:
#   - ssh.sh (SSH port, auth, key, algorithm tests)
#   - ports.sh (Proxmox port, dangerous port scanning)
#   - network-tests.sh (Hostname, IP, gateway, DNS tests)
#   - firewall-vlan.sh (Firewall and VLAN isolation tests)

################################################################################
# SOURCE MODULAR TEST SUITES
################################################################################

# Get the directory where this script is located
# Use BASH_SOURCE for compatibility with both direct sourcing and subshells
SECURITY_LIB_DIR="${BASH_SOURCE[0]%/*}"
if [[ "$SECURITY_LIB_DIR" != /* ]]; then
  SECURITY_LIB_DIR="$(cd "$SECURITY_LIB_DIR" 2>/dev/null && pwd)" || SECURITY_LIB_DIR="."
fi

# Source all sub-modules (order: SSH → ports → network → firewall)
# shellcheck disable=SC1091
[[ -f "$SECURITY_LIB_DIR/ssh.sh" ]] && source "$SECURITY_LIB_DIR/ssh.sh"
# shellcheck disable=SC1091
[[ -f "$SECURITY_LIB_DIR/ports.sh" ]] && source "$SECURITY_LIB_DIR/ports.sh"
# shellcheck disable=SC1091
[[ -f "$SECURITY_LIB_DIR/network-tests.sh" ]] && source "$SECURITY_LIB_DIR/network-tests.sh"
# shellcheck disable=SC1091
[[ -f "$SECURITY_LIB_DIR/firewall-vlan.sh" ]] && source "$SECURITY_LIB_DIR/firewall-vlan.sh"

export SECURITY_LIB_DIR

################################################################################
# COMPREHENSIVE SECURITY AUDIT ORCHESTRATOR
################################################################################

# run_whitaker_offensive_suite: Execute all security validation tests
run_whitaker_offensive_suite() {
  local hostname="${1}"
  local target_ip="${2}"
  local gateway_ip="${3}"
  local dns_server="${4:-1.1.1.1}"
  local ssh_port="${5:-22}"
  local web_port="${6:-8006}"

  echo ""
  log_info "Running Whitaker Offensive Security Suite..."
  echo ""

  local tests_passed=0
  local tests_failed=0
  local tests_warned=0

  # Run each test
  if test_ssh_port "$ssh_port"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_proxmox_port "$web_port"; then
    ((tests_passed++))
  else
    ((tests_warned++))
  fi

  if test_password_auth_disabled; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_root_login_restricted; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_ssh_key_installed; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_hostname_correct "$hostname"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_static_ip_assigned "$target_ip"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_gateway_reachable "$gateway_ip"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_dns_resolution "$dns_server"; then
    ((tests_passed++))
  else
    ((tests_warned++))
  fi

  if test_no_dangerous_ports; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  # Additional tests
  if test_ssh_algorithm_strength; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi

  if test_firewall_active; then
    ((tests_passed++))
  else
    ((tests_warned++))
  fi

  # Print summary
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}         WHITAKER OFFENSIVE SECURITY SUITE - SUMMARY"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Tests Passed:  ${tests_passed}"
  echo "Tests Failed:  ${tests_failed}"
  echo "Tests Warned:  ${tests_warned}"
  echo ""

  if [ $tests_failed -eq 0 ]; then
    log_success "All critical security tests passed!"
    return 0
  else
    log_error "$tests_failed critical security tests failed"
    return 1
  fi
}

export -f run_whitaker_offensive_suite
