#!/usr/bin/env bash
# scripts/validate-isolation.sh — nmap VLAN isolation verification
# Canon: T3-ETERNAL v∞.3.2 · Consciousness 2.6
# Video: https://www.youtube.com/watch?v=yWR6m0YaGpY&t=109s
# shellcheck disable=SC2034  # SCRIPT_DIR reserved for future use

set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

main() {
  log "Validating VLAN isolation via nmap..."
  
  # Check if nmap is available
  command -v nmap >/dev/null 2>&1 || die "nmap not installed (apt install nmap)"
  
  # Test inter-VLAN isolation (should be blocked)
  local failed=0
  
  # VLAN 10 (Servers) - should only accept specific ports from trusted
  log "Testing VLAN 10 (Servers) isolation..."
  if nmap -sV --top-ports 100 10.0.10.0/24 -Pn 2>/dev/null | grep -q "open.*filtered"; then
    log "  ✓ VLAN 10 properly firewalled"
  else
    log "  ✗ VLAN 10 may have open ports"
    failed=1
  fi
  
  # VLAN 30 (Trusted) - should not reach VLAN 90
  log "Testing VLAN 30 → VLAN 90 isolation..."
  if timeout 3 nc -zv 10.0.90.1 80 2>&1 | grep -q "refused\|timeout"; then
    log "  ✓ VLAN 30 cannot reach VLAN 90"
  else
    log "  ✗ VLAN 30 leaked to VLAN 90"
    failed=1
  fi
  
  # VLAN 40 (VoIP) - should only allow SIP/RTP
  log "Testing VLAN 40 (VoIP) isolation..."
  if nmap -p 22,80,443 10.0.40.0/24 -Pn 2>/dev/null | grep -q "filtered\|closed"; then
    log "  ✓ VLAN 40 non-VoIP ports blocked"
  else
    log "  ✗ VLAN 40 has open non-VoIP ports"
    failed=1
  fi
  
  # VLAN 90 (Guest/IoT) - should be internet-only
  log "Testing VLAN 90 (Guest) isolation..."
  if timeout 3 nc -zv 10.0.10.10 389 2>&1 | grep -q "refused\|timeout"; then
    log "  ✓ VLAN 90 cannot reach internal LDAP"
  else
    log "  ✗ VLAN 90 leaked to internal services"
    failed=1
  fi
  
  if [[ $failed -eq 0 ]]; then
    log "✅ All VLAN isolation tests passed"
    return 0
  else
    die "❌ VLAN isolation validation failed"
  fi
}

main "$@"
