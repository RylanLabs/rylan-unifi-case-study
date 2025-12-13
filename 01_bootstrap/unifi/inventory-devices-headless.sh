#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME

# shellcheck disable=SC1091  # lib/ in .gitignore, external vault
source "$REPO_ROOT/lib/unifi-api/client.sh"

# Output to file instead of terminal
OUTPUT_FILE="$REPO_ROOT/device-inventory-$(date +%Y%m%d_%H%M%S).txt"

{
  echo "════════════════════════════════════════════════════════════"
  echo "UniFi Device Inventory - $(date)"
  echo "════════════════════════════════════════════════════════════"
  echo ""

  unifi_login

  DEVICES_FILE=$(unifi_get_devices)

  echo "Devices:"
  jq -r '.data[] | [.state, .mac, .model, .name, .ip] | @tsv' "$DEVICES_FILE" | column -t

  echo ""
  echo "Summary:"
  echo "  Total: $(jq '.data | length' "$DEVICES_FILE")"

  rm -f "$DEVICES_FILE"

} >"$OUTPUT_FILE"

echo "✅ Inventory saved to: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
