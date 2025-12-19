#!/usr/bin/env bash
# Script: runbooks/ministry_detection/apply.sh
# Purpose: Network isolation tests, auth validation, comprehensive validation
# Guardian: Beale | Trinity: Carter → Bauer → Beale
# Date: 2025-12-13
# Consciousness: 5.2
# EXCEED: 350 lines — 10 functions (verify_service, test_ldap, test_radius, test_firewall,
#         test_isolation, verify_certs, verify_fail2ban, verify_audit, check_resources, summary)
#         Rationale: Comprehensive detection/validation requires 10 distinct test domains
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

source "${REPO_ROOT}/lib/ignite-utils.sh"

# State tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Phase execution
validate() {
  log phase "MINISTRY OF DETECTION (Beale Validation)"

  verify_service
  test_ldap
  test_radius
  test_firewall
  test_isolation
  verify_certs
  verify_fail2ban
  verify_audit
  check_resources
  summary

  if [[ $CHECKS_FAILED -eq 0 ]]; then
    log success "PHASE 3 COMPLETE — Beale Detection Validated"
    return 0
  else
    die "PHASE 3 FAILED — $CHECKS_FAILED checks failed"
  fi
}

verify_service() {
  log step "Verifying FreeRADIUS service status"

  if systemctl is-active --quiet freeradius; then
    log success "✓ FreeRADIUS service active"
    ((CHECKS_PASSED++)) || true
  else
    log error "✗ FreeRADIUS service inactive"
    ((CHECKS_FAILED++)) || true
  fi
}

test_ldap() {
  log step "Testing LDAP connectivity"

  if timeout 5 bash -c "echo > /dev/tcp/10.0.10.10/636" 2>/dev/null; then
    log success "✓ LDAPS port 636 accessible"
    ((CHECKS_PASSED++)) || true
  else
    log warn "⚠ LDAPS port 636 not accessible (may require network setup)"
    ((WARNINGS++)) || true
  fi

  # Test LDAP search (requires valid bind DN)
  if ldapsearch -x -H ldaps://10.0.10.10 -b "dc=rylan,dc=internal" \
    -D "cn=freeradius,ou=Services,dc=rylan,dc=internal" \
    -w "${LDAP_PASS:-}" "(cn=*)" >/dev/null 2>&1; then
    log success "✓ LDAP search successful"
    ((CHECKS_PASSED++)) || true
  else
    log warn "⚠ LDAP search failed (LDAP_PASS may not be set)"
    ((WARNINGS++)) || true
  fi
}

test_radius() {
  log step "Testing RADIUS authentication"

  if ! command -v radtest &>/dev/null; then
    log warn "⚠ radtest not available (freeradius-utils needed)"
    ((WARNINGS++)) || true
    return
  fi

  # Test localhost auth
  if radtest -x testing localhost 1812 testing123 0 &>/dev/null; then
    log success "✓ RADIUS localhost auth works"
    ((CHECKS_PASSED++)) || true
  else
    log warn "⚠ RADIUS localhost auth failed (expected for production)"
    ((WARNINGS++)) || true
  fi
}

test_firewall() {
  log step "Testing nftables firewall rules"

  if nft list ruleset | grep -q "udp dport 1812"; then
    log success "✓ RADIUS auth port (1812) rule present"
    ((CHECKS_PASSED++)) || true
  else
    log error "✗ RADIUS auth port rule missing"
    ((CHECKS_FAILED++)) || true
  fi

  if nft list ruleset | grep -q "udp dport 1813"; then
    log success "✓ RADIUS acct port (1813) rule present"
    ((CHECKS_PASSED++)) || true
  else
    log error "✗ RADIUS acct port rule missing"
    ((CHECKS_FAILED++)) || true
  fi

  # Count rules (Beale: ≤10)
  local rule_count
  rule_count=$(nft list ruleset | grep -c "accept\|drop\|reject" || echo 0)
  if [[ $rule_count -le 10 ]]; then
    log success "✓ Firewall rules within Beale limit ($rule_count/10)"
    ((CHECKS_PASSED++)) || true
  else
    log warn "⚠ Firewall rules exceed limit ($rule_count/10)"
    ((WARNINGS++)) || true
  fi
}

test_isolation() {
  log step "Testing network isolation"

  # Test isolation from trusted VLAN (10.0.30.0/24)
  if timeout 2 ping -c 1 10.0.30.1 &>/dev/null; then
    log warn "⚠ Can reach VLAN 30 (isolation may not be configured)"
    ((WARNINGS++)) || true
  else
    log success "✓ Isolated from VLAN 30 (trusted)"
    ((CHECKS_PASSED++)) || true
  fi

  # Test isolation from guest VLAN (10.0.90.0/24)
  if timeout 2 ping -c 1 10.0.90.1 &>/dev/null; then
    log warn "⚠ Can reach VLAN 90 (isolation may not be configured)"
    ((WARNINGS++)) || true
  else
    log success "✓ Isolated from VLAN 90 (guest)"
    ((CHECKS_PASSED++)) || true
  fi
}

verify_certs() {
  log step "Verifying certificate configuration"

  if [[ -f /etc/freeradius/3.0/certs/rylan-ca.pem ]]; then
    log success "✓ CA certificate present"
    ((CHECKS_PASSED++)) || true
  else
    log error "✗ CA certificate missing"
    ((CHECKS_FAILED++)) || true
  fi

  if [[ -f /etc/freeradius/3.0/certs/server.pem ]]; then
    log success "✓ Server certificate present"
    ((CHECKS_PASSED++)) || true

    # Check expiration
    local expiry_date
    expiry_date=$(openssl x509 -in /etc/freeradius/3.0/certs/server.pem \
      -noout -enddate 2>/dev/null | cut -d= -f2)
    local expiry_epoch
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local now_epoch
    now_epoch=$(date +%s)
    local days_left
    days_left=$(((expiry_epoch - now_epoch) / 86400))

    if [[ $days_left -gt 0 ]]; then
      log success "✓ Certificate valid for $days_left days"
      ((CHECKS_PASSED++)) || true
    else
      log error "✗ Certificate expired"
      ((CHECKS_FAILED++)) || true
    fi
  else
    log error "✗ Server certificate missing"
    ((CHECKS_FAILED++)) || true
  fi
}

verify_fail2ban() {
  log step "Verifying fail2ban status"

  if systemctl is-active --quiet fail2ban; then
    log success "✓ fail2ban service running"
    ((CHECKS_PASSED++)) || true

    if fail2ban-client status freeradius >/dev/null 2>&1; then
      log success "✓ FreeRADIUS jail configured"
      ((CHECKS_PASSED++)) || true
    else
      log warn "⚠ FreeRADIUS jail not active yet"
      ((WARNINGS++)) || true
    fi
  else
    log error "✗ fail2ban service not running"
    ((CHECKS_FAILED++)) || true
  fi
}

verify_audit() {
  log step "Verifying audit logging"

  if systemctl is-active --quiet auditd; then
    log success "✓ auditd service running"
    ((CHECKS_PASSED++)) || true

    if auditctl -l | grep -q "freeradius"; then
      log success "✓ FreeRADIUS audit rules loaded"
      ((CHECKS_PASSED++)) || true
    else
      log warn "⚠ FreeRADIUS audit rules not loaded"
      ((WARNINGS++)) || true
    fi
  else
    log error "✗ auditd service not running"
    ((CHECKS_FAILED++)) || true
  fi
}

check_resources() {
  log step "Checking system resources"

  # CPU usage (should be <30% idle)
  local cpu_usage
  cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo 0)

  # Memory usage
  local mem_usage
  mem_usage=$(free 2>/dev/null | grep Mem | awk '{printf "%.1f", $3/$2 * 100}' || echo 0)

  if (($(echo "$cpu_usage < 80" | bc -l 2>/dev/null))); then
    log success "✓ CPU usage: ${cpu_usage}%"
    ((CHECKS_PASSED++)) || true
  else
    log warn "⚠ High CPU usage: ${cpu_usage}%"
    ((WARNINGS++)) || true
  fi

  if (($(echo "$mem_usage < 80" | bc -l 2>/dev/null))); then
    log success "✓ Memory usage: ${mem_usage}%"
    ((CHECKS_PASSED++)) || true
  else
    log warn "⚠ High memory usage: ${mem_usage}%"
    ((WARNINGS++)) || true
  fi
}

summary() {
  echo ""
  log phase "VALIDATION SUMMARY"
  log step "Checks Passed: $CHECKS_PASSED"
  log step "Checks Failed: $CHECKS_FAILED"
  log step "Warnings:      $WARNINGS"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  validate
fi
