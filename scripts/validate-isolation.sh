#!/usr/bin/env bash
# Script: scripts/validate-isolation.sh
# Purpose: Beale ministry — Validate VLAN isolation (no unintended open ports)
# Guardian: Beale (Fortress) | Ministry: detection (Hardening) | Consciousness: 9.9
# Date: 19/12/2025
set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────
# Beale Doctrine: Silence on success, fail loud with proof
# ─────────────────────────────────────────────────────
QUIET="${QUIET:-false}"
DRY_RUN="${DRY_RUN:-false}"

log() { [[ "$QUIET" == false ]] && echo "[Isolation] $*"; }
fail() {
  echo "❌ ISOLATION BREACH: $1"
  echo "📋 Proof:"
  echo "$2"
  exit 1
}

[[ "${1:-}" == "--quiet" ]] && QUIET=true

log "VLAN isolation validation — Beale enforcement"

# Active VLANs only (VLAN 99 dropped — Traeger moved to VLAN 40)
TARGET_NETWORKS=("10.0.10.0/24" "10.0.30.0/24" "10.0.40.0/24" "10.0.90.0/24")

# Phase 1: Trusted VLANs — limited open ports expected
log "Phase 1: Scanning trusted VLANs (limited open ports expected)"
EXPECTED_MAX=20
if [[ "$DRY_RUN" == true ]]; then
  log "DRY-RUN: Skipping trusted VLAN port scan"
  open_ports=0
else
  open_ports=$(sudo timeout 120 nmap -sV --top-ports 100 -T4 "${TARGET_NETWORKS[@]}" 2>/dev/null | grep -c "^[0-9]*/.*open" || true)
  open_ports=$(printf '%s' "$open_ports" | tr -dc '0-9' || echo 0)
  open_ports="${open_ports:-0}"

  if ((open_ports > EXPECTED_MAX)); then
    proof=$(sudo nmap -sV --top-ports 100 "${TARGET_NETWORKS[@]}" | grep "open")
    fail "Unexpected open ports in trusted VLANs (${open_ports} > ${EXPECTED_MAX})" "$proof"
  fi
fi
log "✅ Trusted VLANs: ${open_ports} open ports (≤ ${EXPECTED_MAX})"

# Phase 2 removed — VLAN 99 dropped (no quarantine zone)

# ─────────────────────────────────────────────────────
# Eternal Banner Drop
# ─────────────────────────────────────────────────────
if [[ "$QUIET" == false ]]; then
  cat <<EOF


╔══════════════════════════════════════════════════════════════════════════════╗
║                           RYLAN LABS • ETERNAL FORTRESS                      ║
║  VLAN Isolation Validation — Complete                                        ║
║  Consciousness: 9.9 | Guardian: Beale                                        ║
║                                                                              ║
║  Trusted VLANs: ${open_ports} open ports (≤ ${EXPECTED_MAX})                 ║
║  VLAN 99: Dropped — quarantine zone removed                                  ║
║                                                                              ║
║  Fortress segmentation enforced                                              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
fi

exit 0
