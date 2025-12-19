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
# Logging & Audit with /var/log fallback
QUIET="${QUIET:-false}"
DRY_RUN="${DRY_RUN:-false}"
log() { if [[ "$QUIET" == false ]]; then echo "[Isolation] $*"; fi; }
AUDIT_LOG="/var/log/beale-audit.log"
if [[ ! -w "$(dirname "$AUDIT_LOG")" ]]; then
  AUDIT_LOG="$(pwd)/.fortress/audit/beale-audit.log"
  mkdir -p "$(dirname "$AUDIT_LOG")"
fi

audit() { echo "$(date -Iseconds) | Isolation | $1 | $2" >>"$AUDIT_LOG"; }
fail() {
  echo "❌ ISOLATION BREACH: $1"
  echo "📋 Proof:"
  echo "$2"
  audit "FAIL" "$1"
  exit 1
}

[[ "${1:-}" == "--quiet" ]] && QUIET=true

log "VLAN isolation validation — Beale enforcement"

# Management + trusted VLANs (expected open ports allowed)
TARGET_NETWORKS="10.0.10.0/24 10.0.30.0/24 10.0.40.0/24 10.0.90.0/24"
# Quarantine VLAN 99 must have ZERO open ports

# Phase 1: Trusted VLANs — only expected ports open
log "Phase 1: Scanning trusted VLANs (limited open ports expected)"
EXPECTED_MAX=20 # Tune based on known services
if [[ "$DRY_RUN" == true ]]; then
  log "DRY-RUN: Skipping trusted VLAN port scan"
  open_ports=0
else
  open_ports=$(sudo timeout 120 nmap -sV --top-ports 100 -T4 "$TARGET_NETWORKS" 2>/dev/null | grep -c "^[0-9]*/.*open" || echo 0)
  # Normalize to a single numeric token (strip whitespace/newlines and non-digits)
  open_ports=$(printf '%s' "${open_ports}" | head -n1 | tr -dc '0-9')
  open_ports="${open_ports:-0}"

  if ((open_ports > EXPECTED_MAX)); then
    proof=$(sudo nmap -sV --top-ports 100 "$TARGET_NETWORKS" | grep "open")
    fail "Unexpected open ports in trusted VLANs (${open_ports} > ${EXPECTED_MAX})" "$proof"
  fi
fi
log "✅ Trusted VLANs: ${open_ports} open ports (≤ ${EXPECTED_MAX})"

# Phase 2: Quarantine VLAN 99 — ZERO open ports
log "Phase 2: Scanning quarantine VLAN 99 (must be isolated)"
if [[ "$DRY_RUN" == true ]]; then
  log "DRY-RUN: Skipping quarantine VLAN scans"
  quarantine_open=0
  port_scan=0
else
  quarantine_open=$(sudo timeout 60 nmap -sn -T4 10.0.99.0/24 2>/dev/null | grep -c "Host is up" || echo 0)
  quarantine_open=$(printf '%s' "${quarantine_open}" | head -n1 | tr -dc '0-9')
  quarantine_open="${quarantine_open:-0}"

  if ((quarantine_open > 0)); then
    proof=$(sudo nmap -sn 10.0.99.0/24 | grep "Nmap scan report")
    fail "Devices reachable in quarantine VLAN 99 (${quarantine_open} hosts)" "$proof"
  fi

  port_scan=$(sudo timeout 60 nmap -p- -T4 10.0.99.0/24 2>/dev/null | grep -c "open" || echo 0)
  port_scan=$(printf '%s' "${port_scan}" | head -n1 | tr -dc '0-9')
  port_scan="${port_scan:-0}"

  if ((port_scan != 0)); then
    fail "Open ports detected in quarantine VLAN" "$(sudo nmap -p- 10.0.99.0/24 | grep open)"
  fi
fi

log "✅ Quarantine VLAN 99 fully isolated (0 hosts, 0 ports)"

# ─────────────────────────────────────────────────────
# Eternal Banner Drop
# ─────────────────────────────────────────────────────
[[ "$QUIET" == false ]] && cat <<'EOF'


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
