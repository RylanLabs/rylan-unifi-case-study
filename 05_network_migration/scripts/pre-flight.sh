#!/bin/bash
# 05-network-migration/scripts/pre-flight.sh
# Purpose: Pre-migration validation (Bauer: Trust nothing)
# Author: DT/Luke canonical
# Date: 2025-12-10
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME

# shellcheck disable=SC1091  # lib/ in .gitignore, external vault
source "$REPO_ROOT/lib/unifi-api/client.sh"

echo "════════════════════════════════════════════════════════════"
echo "PRE-MIGRATION VALIDATION"
echo "════════════════════════════════════════════════════════════"
echo ""

unifi_login

# 1. Device connectivity
echo "[1/4] Checking device connectivity..."
DEVICES_FILE=$(unifi_get_devices)

TOTAL=$(jq '.data | length' "$DEVICES_FILE")
CONNECTED=$(jq '[.data[] | select(.state == 1)] | length' "$DEVICES_FILE")

if [ "$CONNECTED" -eq "$TOTAL" ]; then
  echo "  ✅ All $TOTAL devices connected"
else
  echo "  ⚠️  Only $CONNECTED/$TOTAL connected"
  jq -r '.data[] | select(.state != 1) | "    - \(.name // .mac): state \(.state)"' "$DEVICES_FILE"
fi

rm -f "$DEVICES_FILE"

# 2. Controller reachability
echo ""
echo "[2/4] Testing controller reachability..."
if ping -c 3 -W 2 192.168.1.13 >/dev/null 2>&1; then
  echo "  ✅ Controller reachable"
else
  echo "  ❌ Controller unreachable"
  exit 1
fi

# 3. Backup current config
echo ""
echo "[3/4] Backing up current configuration..."
BACKUP_DIR="$SCRIPT_DIR/../backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

DEVICES_BACKUP=$(unifi_get_devices)
cp "$DEVICES_BACKUP" "$BACKUP_DIR/devices.json"
rm -f "$DEVICES_BACKUP"

NETWORKS_BACKUP=$(unifi_get_networks)
cp "$NETWORKS_BACKUP" "$BACKUP_DIR/networks.json"
rm -f "$NETWORKS_BACKUP"

FIREWALL_BACKUP=$(unifi_get_firewall_rules)
cp "$FIREWALL_BACKUP" "$BACKUP_DIR/firewall.json"
rm -f "$FIREWALL_BACKUP"

echo "  ✅ Backup saved to: $BACKUP_DIR"

# 4. Validate config files
echo ""
echo "[4/4] Validating configuration files..."

if jq empty "$SCRIPT_DIR/../configs/vlans.json" 2>/dev/null; then
  VLAN_COUNT=$(jq '.networks | length' "$SCRIPT_DIR/../configs/vlans.json")
  echo "  ✅ vlans.json valid ($VLAN_COUNT VLANs defined)"
else
  echo "  ❌ vlans.json invalid"
  exit 1
fi

if jq empty "$SCRIPT_DIR/../configs/firewall-rules.json" 2>/dev/null; then
  RULE_COUNT=$(jq '.rules | length' "$SCRIPT_DIR/../configs/firewall-rules.json")
  echo "  ✅ firewall-rules.json valid ($RULE_COUNT rules defined)"

  if [ "$RULE_COUNT" -le 10 ]; then
    echo "  ✅ Rule count ≤10 (Hellodeolu compliant)"
  else
    echo "  ⚠️  Rule count >10 (may impact performance)"
  fi
else
  echo "  ❌ firewall-rules.json invalid"
  exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ PRE-FLIGHT COMPLETE - Ready for migration"
echo "════════════════════════════════════════════════════════════"
