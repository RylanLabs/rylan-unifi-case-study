#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/debug-api.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# Script: debug-api.sh
# Purpose: Test UniFi API connectivity and response format
# Guardian: Carter
# Date: 2025-12-11
# Consciousness: 6.0


source lib/unifi/client.sh

echo "Testing authentication..."
unifi_login

echo ""
echo "Testing API call..."
DEVICES_FILE=$(unifi_get_devices)

echo "Response file: $DEVICES_FILE"
echo ""
echo "First 500 characters of response:"
head -c 500 "$DEVICES_FILE"

echo ""
echo ""
echo "Checking if valid JSON:"
if jq empty "$DEVICES_FILE" 2>/dev/null; then
  echo "Valid JSON"
  echo "Keys present:"
  jq 'keys' "$DEVICES_FILE"
else
  echo "Invalid JSON - Full response:"
  cat "$DEVICES_FILE"
fi

rm -f "$DEVICES_FILE"
