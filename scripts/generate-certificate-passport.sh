#!/usr/bin/env bash
set -euo pipefail

# Description: TLS certificate inventory and expiry tracking
# Requires: certificate-passport.json
# Consciousness: 2.6
# Runtime: 4

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/inventory/certificate-passport.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

CERT_PATHS=(
  "/etc/ssl/certs"
  "/etc/letsencrypt/live"
  "/opt/rylan/certs"
  "/var/lib/unifi/cert"
)

CERTS="[]"

for CERT_DIR in "${CERT_PATHS[@]}"; do
  [[ -d "${CERT_DIR}" ]] || continue
  
  while IFS= read -r -d '' CERT_FILE; do
    CN=$(openssl x509 -in "${CERT_FILE}" -noout -subject 2>/dev/null | sed -n 's/.*CN[[:space:]]*=[[:space:]]*\([^,]*\).*/\1/p' || echo "")
    ISSUER=$(openssl x509 -in "${CERT_FILE}" -noout -issuer 2>/dev/null | sed -n 's/.*CN[[:space:]]*=[[:space:]]*\([^,]*\).*/\1/p' || echo "")
    EXPIRY=$(openssl x509 -in "${CERT_FILE}" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")
    
    [[ -n "${CN}" ]] || continue
    
    EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s 2>/dev/null || echo "0")
    DAYS_REMAINING=$(( (EXPIRY_EPOCH - $(date +%s)) / 86400 ))
    
    CERTS=$(echo "${CERTS}" | jq --arg path "${CERT_FILE}" --arg cn "${CN}" \
      --arg issuer "${ISSUER}" --arg expiry "${EXPIRY}" --arg days "${DAYS_REMAINING}" \
      '. += [{path: $path, common_name: $cn, issuer: $issuer, expiry_date: $expiry, days_remaining: ($days | tonumber)}]')
  done < <(find "${CERT_DIR}" -type f \( -name "*.crt" -o -name "*.pem" -o -name "cert.pem" \) -print0 2>/dev/null)
done

CERTS=$(echo "${CERTS}" | jq 'sort_by(.days_remaining)')

cat > "${OUTPUT}" <<EOF
{
  "schema_version": "1.0.0-eternal",
  "generated_at": "${TIMESTAMP}",
  "consciousness": 2.6,
  "certificates": ${CERTS},
  "auto_renew_threshold_days": 30,
  "signature": "$(echo -n "${CERTS}" | sha256sum | awk '{print $1}')"
}
EOF

jq empty "${OUTPUT}" || { echo "❌ Invalid JSON"; exit 1; }

EXPIRING=$(echo "${CERTS}" | jq '[.[] | select(.days_remaining < 30)] | length')
[[ "${EXPIRING}" -eq 0 ]] || echo "⚠️  ${EXPIRING} certificate(s) expiring <30 days"

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(bauer): generate certificate-passport.json — $(echo "${CERTS}" | jq '. | length') certs, ${EXPIRING} expiring" --quiet 2>/dev/null || true

echo "✓ ${OUTPUT}"
