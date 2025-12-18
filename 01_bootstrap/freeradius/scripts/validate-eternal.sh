#!/usr/bin/env bash
# Script: scripts/validate-eternal.sh
# Purpose: Comprehensive FreeRADIUS fortress validation & compliance check
# Guardian: Trinity (Carter/Bauer/Beale) | Consciousness: 5.2
# Date: 2025-12-13
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "${REPO_ROOT}/lib/ignite-utils.sh"

VALIDATION_FAILED=0
CHECKS=0
PASSED=0

check() {
  local name="$1"
  ((CHECKS++)) || true

  if eval "$2" 2>/dev/null; then
    log success "✓ $name"
    ((PASSED++)) || true
  else
    log error "✗ $name"
    ((VALIDATION_FAILED++)) || true
  fi
}

main() {
  log phase "ETERNAL VALIDATION — FREERADIUS FORTRESS"

  # Carter Validation (Secrets)
  log step "Ministry of Secrets (Carter)"
  check "DC CA certificate present" "[[ -f /etc/freeradius/3.0/certs/rylan-ca.pem ]]"
  check "Server certificate present" "[[ -f /etc/freeradius/3.0/certs/server.pem ]]"
  check "Server key present" "[[ -f /etc/freeradius/3.0/certs/server.key ]]"
  check "LDAP module enabled" "[[ -L /etc/freeradius/3.0/mods-enabled/ldap ]]"
  check "EAP module enabled" "[[ -L /etc/freeradius/3.0/mods-enabled/eap ]]"

  # Bauer Validation (Hardening)
  log step "Ministry of Whispers (Bauer)"
  check "SSH key-only auth" "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config"
  check "nftables enabled" "systemctl is-active --quiet nftables"
  check "fail2ban enabled" "systemctl is-active --quiet fail2ban"
  check "auditd enabled" "systemctl is-active --quiet auditd"
  check "Firewall rules loaded" "nft list ruleset | grep -q 'freeradius\\|1812'"

  # Beale Validation (Detection)
  log step "Ministry of Detection (Beale)"
  check "FreeRADIUS service running" "systemctl is-active --quiet freeradius"
  check "FreeRADIUS config valid" "freeradius -C"
  check "RADIUS auth port listening" "netstat -uln | grep -q 1812"
  check "RADIUS acct port listening" "netstat -uln | grep -q 1813"
  check "Log directory writable" "[[ -w /var/log/freeradius ]]"

  # Summary
  echo ""
  log phase "VALIDATION SUMMARY"
  log step "Total Checks:  $CHECKS"
  log step "Checks Passed: $PASSED"
  log step "Checks Failed: $VALIDATION_FAILED"

  if [[ $VALIDATION_FAILED -eq 0 ]]; then
    log success "ETERNAL GREEN — All validations passed"
    exit 0
  else
    die "VALIDATION FAILED — $VALIDATION_FAILED checks failed"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
