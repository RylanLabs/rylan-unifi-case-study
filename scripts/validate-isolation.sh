#!/usr/bin/env bash
# Script: scripts/validate-isolation.sh
# Purpose: Beale ministry — Validate VLAN isolation (no unintended open ports)
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
set -euo pipefail

# ─────────────────────────────────────────────────────
# Beale Doctrine: Silence on success, fail loud with proof
# ─────────────────────────────────────────────────────
log()   { [[ "$QUIET" == false ]] && echo "[Isolation] $*"; }
audit() { echo "$(date -Iseconds) | Isolation | $1 | $2" >> /var/log/beale-audit.log; }
fail()  { echo "❌ ISOLATION BREACH: $1"; echo "📋 Proof:"; echo "$2"; audit "FAIL" "$1"; exit 1; }

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

log "VLAN isolation validation — Beale enforcement"

mkdir -p /var/log

# Management + trusted VLANs (expected open ports allowed)
TARGET_NETWORKS="10.0.10.0/24 10.0.30.0/24 10.0.40.0/24 10.0.90.0/24"
# Quarantine VLAN 99 must have ZERO open ports

# Phase 1: Trusted VLANs — only expected ports open
log "Phase 1: Scanning trusted VLANs (limited open ports expected)"
open_ports=$(sudo timeout 120 nmap -sV --top-ports 100 -T4 "$TARGET_NETWORKS" 2>/dev/null | grep -c "^[0-9]*/.*open" || echo 0)

# Expected: SSH (22), UniFi (8080,8443), etc. — adjust threshold per environment
EXPECTED_MAX=20  # Tune based on known services

if [[ $open_ports -gt $EXPECTED_MAX ]]; then
  proof=$(sudo nmap -sV --top-ports 100 "$TARGET_NETWORKS" | grep "open")
  fail "Unexpected open ports in trusted VLANs ($open_ports > $EXPECTED_MAX)" "$proof"
fi
log "✅ Trusted VLANs: $open_ports open ports (≤ $EXPECTED_MAX)"

# Phase 2: Quarantine VLAN 99 — ZERO open ports
log "Phase 2: Scanning quarantine VLAN 99 (must be isolated)"
quarantine_open=$(sudo timeout 60 nmap -sn -T4 10.0.99.0/24 2>/dev/null | grep -c "Host is up" || echo 0)

if [[ $quarantine_open -gt 0 ]]; then
  proof=$(sudo nmap -sn 10.0.99.0/24 | grep "Nmap scan report")
  fail "Devices reachable in quarantine VLAN 99 ($quarantine_open hosts)" "$proof"
fi

port_scan=$(sudo timeout 60 nmap -p- -T4 10.0.99.0/24 2>/dev/null | grep -c "open" || echo 0)
[[ $port_scan -eq 0 ]] || fail "Open ports detected in quarantine VLAN" "$(sudo nmap -p- 10.0.99.0/24 | grep open)"

log "✅ Quarantine VLAN 99 fully isolated (0 hosts, 0 ports)"

# ─────────────────────────────────────────────────────
# Eternal Banner Drop
# ─────────────────────────────────────────────────────
[[ "$QUIET" == false ]] && cat << 'EOF'


╔══════════════════════════════════════════════════════════════════════════════╗
║                           RYLAN LABS • ETERNAL FORTRESS                      ║
║  VLAN Isolation Validation — Complete                                        ║
║  Consciousness: 4.6 | Guardian: Beale                                        ║
║                                                                              ║
║  Trusted VLANs: $open_ports open ports (≤ $EXPECTED_MAX)                            ║
║  Quarantine VLAN 99: 0 hosts reachable, 0 ports open                         ║
║                                                                              ║
║  Fortress segmentation enforced                                              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

audit "PASS" "trusted_open=$open_ports quarantine_isolated=true"
exit 0
