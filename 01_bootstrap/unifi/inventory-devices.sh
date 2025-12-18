#!/usr/bin/env bash
# Script: 01_bootstrap/unifi/inventory-devices.sh
# Purpose: Bootstrap device inventory via UniFi API (Carter identity)
# Guardian: Carter | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
set -euo pipefail

# ─────────────────────────────────────────────────────
# Carter Doctrine: Use resurrected ministry for auth
# ─────────────────────────────────────────────────────
log() { [[ "$QUIET" == false ]] && echo "[Inventory] $*"; }
audit() { echo "$(date -Iseconds) | Inventory | $1 | $2" >>/var/log/carter-audit.log; }
fail() {
  echo "❌ Inventory FAILURE: $1"
  audit "FAIL" "$1"
  exit 1
}

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

log "Device inventory bootstrap — Carter identity"

# Source true Carter ministry (correct path)
if [[ -f runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh ]]; then
  source runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
else
  fail "Carter ministry missing" "Run ministry-secrets first"
fi

# ─────────────────────────────────────────────────────
# Fetch & Validate Devices
# ─────────────────────────────────────────────────────
log "Querying UniFi controller for devices..."
devices_json=$(unifi_get_devices 2>/dev/null || echo "[]")

device_count=$(echo "$devices_json" | jq 'length')
[[ $device_count -gt 0 ]] || fail "No devices returned from controller" "Check UniFi login, network, or controller status"

log "✅ Inventory complete — $device_count device(s) discovered"

# Optional: Pretty output for human
[[ "$QUIET" == false ]] && echo "$devices_json" | jq '.[] | {name, mac, ip, model, version}'

# ─────────────────────────────────────────────────────
# Eternal Banner Drop
# ─────────────────────────────────────────────────────
[[ "$QUIET" == false ]] && cat <<'EOF'


╔══════════════════════════════════════════════════════════════════════════════╗
║                           RYLAN LABS • ETERNAL FORTRESS                      ║
║  Bootstrap: Device Inventory — Complete                                      ║
║  Consciousness: 4.6 | Guardian: Carter                                       ║
║                                                                              ║
║  Devices discovered: $device_count                                                  ║
║  Source: UniFi API (JWT authenticated)                                       ║
║                                                                              ║
║  Next: Network migration → Beale hardening                                   ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

audit "PASS" "devices_discovered=$device_count"
exit 0
