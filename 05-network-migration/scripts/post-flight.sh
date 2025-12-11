#!/bin/bash
# 05-network-migration/scripts/post-flight.sh
# Purpose: Post-migration validation (Whitaker: Offensive testing)
# Author: DT/Luke canonical
# Date: 2025-12-10
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME

source "$REPO_ROOT/lib/unifi-api/client.sh"

echo "════════════════════════════════════════════════════════════"
echo "POST-MIGRATION VALIDATION"
echo "════════════════════════════════════════════════════════════"
echo ""

unifi_login

# 1. Device connectivity
echo "[1/4] Verifying device connectivity..."
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

# 2. VLAN verification
echo ""
echo "[2/4] Verifying VLAN configuration..."
NETWORKS_FILE=$(unifi_get_networks)

EXPECTED_VLANS=("VLAN10_Management" "VLAN30_IoT" "VLAN40_Guest" "VLAN90_Security")

for vlan in "${EXPECTED_VLANS[@]}"; do
  if jq -e --arg name "$vlan" '.data[] | select(.name == $name)' "$NETWORKS_FILE" >/dev/null 2>&1; then
    SUBNET=$(jq -r --arg name "$vlan" '.data[] | select(.name == $name) | .ip_subnet' "$NETWORKS_FILE")
    echo "  ✅ $vlan exists ($SUBNET)"
  else
    echo "  ❌ $vlan missing"
  fi
done

rm -f "$NETWORKS_FILE"

# 3. Controller reachability (new IP if migrated)
echo ""
echo "[3/4] Testing controller reachability..."
if ping -c 3 -W 2 192.168.1.13 >/dev/null 2>&1; then
  echo "  ✅ Controller reachable at 192.168.1.13"
else
  echo "  ⚠️  Controller not reachable at old IP"
  if ping -c 3 -W 2 10.0.10.1 >/dev/null 2>&1; then
    echo "  ✅ Controller reachable at 10.0.10.1 (new IP)"
  else
    echo "  ❌ Controller unreachable"
  fi
fi

# 4. API functionality
echo ""
echo "[4/4] Testing API functionality..."
SYSINFO_FILE=$(unifi_api_call "stat/sysinfo")

if jq -e '.data' "$SYSINFO_FILE" >/dev/null 2>&1; then
  echo "  ✅ API responding correctly"
else
  echo "  ❌ API errors detected"
fi

rm -f "$SYSINFO_FILE"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "POST-FLIGHT COMPLETE"
echo "════════════════════════════════════════════════════════════"
