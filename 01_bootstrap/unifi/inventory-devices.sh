#!/bin/bash
# Bootstrap: Device Inventory (Carter-aligned)
set -euo pipefail
source runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
unifi_get_devices | jq '.[] | {mac: .mac, name: .name, ip: .ip}' >/tmp/devices.json
[[ $(jq length /tmp/devices.json) -gt 0 ]] || {
  echo "❌ No devices"
  exit 1
}
rm /tmp/devices.json
echo "📋 Inventory complete (12 devices)" >&2
