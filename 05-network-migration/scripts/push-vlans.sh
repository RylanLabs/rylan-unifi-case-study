#!/bin/bash
# 05-network-migration/scripts/push-vlans.sh
# Purpose: Push VLAN configuration to controller
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

CONFIG_FILE="$SCRIPT_DIR/../configs/vlans.json"

echo "════════════════════════════════════════════════════════════"
echo "VLAN Configuration Push - $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════"
echo ""

unifi_login

# Get existing networks
echo "Fetching existing networks..."
EXISTING_FILE=$(unifi_get_networks)

# Process each VLAN from config
jq -c '.networks[]' "$CONFIG_FILE" | while read -r vlan_config; do
  VLAN_NAME=$(echo "$vlan_config" | jq -r '.name')
  VLAN_ID=$(echo "$vlan_config" | jq -r '.vlan')

  echo ""
  echo "Processing: $VLAN_NAME (VLAN $VLAN_ID)"

  # Check if VLAN exists
  EXISTING_ID=$(jq -r --arg name "$VLAN_NAME" '.data[] | select(.name == $name) | ._id' "$EXISTING_FILE")

  if [ -n "$EXISTING_ID" ]; then
    echo "  ⚠️  VLAN exists (ID: $EXISTING_ID)"
    echo "  Updating configuration..."

    # Add _id to config for update
    UPDATED_CONFIG=$(echo "$vlan_config" | jq --arg id "$EXISTING_ID" '. + {_id: $id}')

    # Update via API
    RESULT_FILE=$(unifi_api_call "rest/networkconf/$EXISTING_ID" PUT "$UPDATED_CONFIG")

    if jq -e '.meta.rc == "ok"' "$RESULT_FILE" >/dev/null 2>&1; then
      echo "  ✅ Updated successfully"
    else
      echo "  ❌ Update failed:"
      jq -r '.meta.msg // "Unknown error"' "$RESULT_FILE"
    fi
    rm -f "$RESULT_FILE"

  else
    echo "  Creating new VLAN..."

    # Create via API
    RESULT_FILE=$(unifi_api_call "rest/networkconf" POST "$vlan_config")

    if jq -e '.meta.rc == "ok"' "$RESULT_FILE" >/dev/null 2>&1; then
      echo "  ✅ Created successfully"
    else
      echo "  ❌ Creation failed:"
      jq -r '.meta.msg // "Unknown error"' "$RESULT_FILE"
    fi
    rm -f "$RESULT_FILE"
  fi
done

rm -f "$EXISTING_FILE"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "VLAN push complete"
echo ""
echo "Current networks:"
NETWORKS_FILE=$(unifi_get_networks)
jq -r '.data[] | "  - \(.name): \(.ip_subnet // "N/A") (VLAN \(.vlan // "N/A"))"' "$NETWORKS_FILE"
rm -f "$NETWORKS_FILE"
echo ""
echo "════════════════════════════════════════════════════════════"
