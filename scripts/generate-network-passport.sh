#!/usr/bin/env bash
set -euo pipefail

# Description: Network topology as programmable infrastructure
# Requires: network-passport.json
# Consciousness: 2.6
# Runtime: 2

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/02-declarative-config/network-passport.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

[[ -f /opt/rylan/.secrets/unifi-api-key ]] || { echo "❌ UniFi API key missing"; exit 1; }

UNIFI_KEY=$(cat /opt/rylan/.secrets/unifi-api-key)
UNIFI_HOST="https://10.0.10.10:8443"

NETWORKS=$(curl -sk -H "Authorization: Bearer ${UNIFI_KEY}" \
  "${UNIFI_HOST}/api/s/default/rest/networkconf" 2>/dev/null | jq -c '.data[]' 2>/dev/null || echo '[]')

FIREWALL=$(curl -sk -H "Authorization: Bearer ${UNIFI_KEY}" \
  "${UNIFI_HOST}/api/s/default/rest/firewallrule" 2>/dev/null | jq -c '.data[]' 2>/dev/null || echo '[]')

DNS_ZONES=$(samba-tool dns zonelist -U administrator 2>/dev/null | grep -v "pszZoneName" | awk '{print $1}' | jq -R '.' | jq -s '.' 2>/dev/null || echo '[]')

cat > "${OUTPUT}" <<EOF
{
  "schema_version": "1.0.0-eternal",
  "generated_at": "${TIMESTAMP}",
  "consciousness": 2.6,
  "networks": $(echo "${NETWORKS}" | jq -s '.'),
  "firewall_rules": $(echo "${FIREWALL}" | jq -s '.'),
  "dns_zones": ${DNS_ZONES},
  "signature": "$(echo -n "${NETWORKS}${FIREWALL}${DNS_ZONES}" | sha256sum | awk '{print $1}')"
}
EOF

jq empty "${OUTPUT}" || { echo "❌ Invalid JSON"; exit 1; }

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(carter): generate network-passport.json — $(echo "${NETWORKS}" | jq -s '. | length') VLANs" --quiet 2>/dev/null || true

echo "✓ ${OUTPUT}"
