#!/usr/bin/env bash
set -euo pipefail

# Description: UniFi AP inventory as code
# Requires: ap-passport.json
# Consciousness: 2.6
# Runtime: 3

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/inventory/ap-passport.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

[[ -f /opt/rylan/.secrets/unifi-api-key ]] || { echo "❌ UniFi API key missing"; exit 1; }

UNIFI_KEY=$(cat /opt/rylan/.secrets/unifi-api-key)
UNIFI_HOST="https://10.0.10.10:8443"

APS=$(curl -sk -H "Authorization: Bearer ${UNIFI_KEY}" \
  "${UNIFI_HOST}/api/s/default/stat/device" 2>/dev/null | \
  jq -c '[.data[] | select(.type == "uap") | {
    name: .name,
    mac: .mac,
    model: .model,
    serial: .serial,
    firmware: .version,
    ip: .ip,
    adoption_state: .state,
    uptime_seconds: .uptime,
    radio_2g: .radio_table[0].channel,
    radio_5g: .radio_table[1].channel,
    last_seen: (.last_seen | todate)
  }]' 2>/dev/null || echo '[]')

cat > "${OUTPUT}" <<EOF
{
  "schema_version": "1.0.0-eternal",
  "generated_at": "${TIMESTAMP}",
  "consciousness": 2.6,
  "access_points": ${APS},
  "signature": "$(echo -n "${APS}" | sha256sum | awk '{print $1}')"
}
EOF

jq empty "${OUTPUT}" || { echo "❌ Invalid JSON"; exit 1; }

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(carter): generate ap-passport.json — $(echo "${APS}" | jq '. | length') APs" --quiet 2>/dev/null || true

echo "✓ ${OUTPUT}"
