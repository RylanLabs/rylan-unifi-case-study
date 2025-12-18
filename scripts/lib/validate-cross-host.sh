#!/usr/bin/env bash
# Script: validate-cross-host.sh
# Purpose: Cross-host validation tests (DNS, LDAP, VLAN, Pi-hole)
# Guardian: The Archivist
# Date: 12/13/2025
# Consciousness: 4.7

# ============================================================================
# CROSS-HOST TESTS (DNS, LDAP, VLAN, Pi-hole)
# ============================================================================

run_cross_host_tests() {
  local POLICY_FILE="$1"

  echo ""
  echo -e "${BLUE}=== Cross-Host Tests ===${NC}"

  # Test 1: Policy Table Rule Count
  printf "Policy table rules (≤10): "
  if [[ -f "${POLICY_FILE}" ]]; then
    RULE_COUNT=$(grep -cE '^  - id:' "${POLICY_FILE}" || echo "0")
    if [[ "${RULE_COUNT}" -le 10 ]]; then
      pass "Found ${RULE_COUNT} rules"
    else
      fail "Found ${RULE_COUNT} rules (exceeds 10-rule limit)"
    fi
  else
    skip "policy-table.yaml not found"
  fi

  # Test 2: DNS Resolution (Samba AD)
  printf "DNS resolution (dc.rylan.internal): "
  if timeout 3 dig +short dc.rylan.internal @10.0.10.10 2>/dev/null | grep -q "10.0.10.10"; then
    pass "Resolves to 10.0.10.10"
  else
    fail "Cannot resolve or resolves to wrong IP"
  fi

  # Test 3: LDAP Connectivity
  printf "LDAP connectivity (port 389): "
  if timeout 3 bash -c "echo > /dev/tcp/10.0.10.10/389" 2>/dev/null; then
    pass "Port 389 reachable"
  else
    fail "Port 389 unreachable (Samba AD down?)"
  fi

  # Test 4: VLAN Isolation
  printf "VLAN isolation (10 → 90 blocked): "
  if timeout 1 ping -c 1 -W 1 10.0.90.1 &>/dev/null; then
    fail "VLAN 90 reachable (isolation broken)"
  else
    pass "VLAN 90 blocked by policy"
  fi

  # Test 5: Pi-hole DNS Upstream
  printf "Pi-hole upstream DNS (10.0.10.11): "
  if timeout 3 bash -c "echo > /dev/tcp/10.0.10.11/53" 2>/dev/null; then
    pass "Pi-hole port 53 reachable"
  else
    fail "Pi-hole unreachable on 10.0.10.11:53"
  fi
}

export -f run_cross_host_tests
