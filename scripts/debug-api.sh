#!/bin/bash
set -euo pipefail

source lib/unifi-api/client.sh

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
  echo "✅ Valid JSON"
  echo "Keys present:"
  jq 'keys' "$DEVICES_FILE"
else
  echo "❌ Invalid JSON - Full response:"
  cat "$DEVICES_FILE"
fi

rm -f "$DEVICES_FILE"
