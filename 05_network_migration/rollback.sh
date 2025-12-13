#!/bin/bash
# 05-network-migration/rollback.sh
# Purpose: Emergency rollback (Hellodeolu: <15 min RTO)
# Author: DT/Luke canonical
# Date: 2025-12-10
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME

# shellcheck disable=SC1091  # lib/ in .gitignore, external vault
source "$REPO_ROOT/lib/unifi-api/client.sh"

echo "════════════════════════════════════════════════════════════"
echo "EMERGENCY ROLLBACK"
echo "════════════════════════════════════════════════════════════"
echo ""

# Find latest backup
LATEST_BACKUP=$(find "$SCRIPT_DIR/backups" -maxdepth 1 -type d | sort -r | head -2 | tail -1)

if [ -z "$LATEST_BACKUP" ] || [ ! -d "$LATEST_BACKUP" ]; then
  echo "❌ No backup found in $SCRIPT_DIR/backups/"
  exit 1
fi

echo "Latest backup: $LATEST_BACKUP"
echo "Backup date: $(basename "$LATEST_BACKUP")"
echo ""
read -r -p "Restore from this backup? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Rollback aborted"
  exit 0
fi

unifi_login

# Restore networks
echo ""
echo "Restoring network configuration..."
if [ -f "$LATEST_BACKUP/networks.json" ]; then
  jq -c '.data[]' "$LATEST_BACKUP/networks.json" | while read -r network; do
    NET_ID=$(echo "$network" | jq -r '._id')
    NET_NAME=$(echo "$network" | jq -r '.name')
    echo "  Restoring: $NET_NAME"

    RESULT_FILE=$(unifi_api_call "rest/networkconf/$NET_ID" PUT "$network")

    if jq -e '.meta.rc == "ok"' "$RESULT_FILE" >/dev/null 2>&1; then
      echo "    ✅ Restored"
    else
      echo "    ⚠️  Failed"
    fi

    rm -f "$RESULT_FILE"
  done
  echo "  ✅ Networks restored"
else
  echo "  ⚠️  No network backup found"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ ROLLBACK COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Wait 60s for devices to reconnect, then verify in GUI"
