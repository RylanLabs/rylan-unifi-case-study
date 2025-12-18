#!/usr/bin/env bash
# Script: 01_bootstrap/unifi/inventory-devices-headless.sh
# Purpose: Headless UniFi device inventory for automated runs (file output)
# Guardian: Carter | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
set -euo pipefail

# ─────────────────────────────────────────────────────
# Carter Doctrine: Silent, auditable, file-based
# ─────────────────────────────────────────────────────
log() { [[ "$QUIET" == false ]] && echo "[Headless Inventory] $*"; }
audit() { echo "$(date -Iseconds) | HeadlessInventory | $1 | $2" >>/var/log/carter-audit.log; }
fail() {
	echo "❌ Headless inventory FAILURE: $1" >&2
	audit "FAIL" "$1"
	exit 1
}

QUIET=true # Headless = silent by default

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
OUTPUT_FILE="$REPO_ROOT/device-inventory-$(date +%Y%m%d_%H%M%S).txt"

log "Headless inventory run — outputting to $OUTPUT_FILE"

# Source Carter API client
source "$REPO_ROOT/lib/unifi/client.sh" || fail "Carter API client missing"

mkdir -p /var/log

{
	cat <<'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                           RYLAN LABS • ETERNAL FORTRESS                      ║
║  Headless Device Inventory — $(date)                                         ║
║  Consciousness: 4.6 | Guardian: Carter                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

	unifi_login >/dev/null

	DEVICES_FILE=$(unifi_get_devices)

	device_count=$(jq '.data | length' "$DEVICES_FILE")

	[[ $device_count -gt 0 ]] || fail "No devices returned from controller" "Check UniFi connectivity, credentials, or controller status"

	echo "Devices discovered: $device_count"
	echo ""
	echo "MAC               Model         Name                  IP             State"
	echo "──────────────────────────────────────────────────────────────────────────────"
	jq -r '.data[] | [.mac, .model, .name // "unnamed", .ip // "no-ip", (.state // 0 | if . == 1 then "connected" else "disconnected" end)] | @tsv' "$DEVICES_FILE" | column -t -s $'\t'

	echo ""
	cat <<'EOF'
═══════════════════════════════════════════════════════════════════════════════
Summary:
  Total devices: $device_count
  Generated: $(date -Iseconds)
  Source: UniFi Network API (headless mode)

Next: Feed into migration or Beale validation
═══════════════════════════════════════════════════════════════════════════════

EOF

	rm -f "$DEVICES_FILE"

} >"$OUTPUT_FILE"

log "✅ Headless inventory complete — saved to $OUTPUT_FILE"
audit "PASS" "devices=$device_count file=$OUTPUT_FILE"

# Silent success (headless)
exit 0
