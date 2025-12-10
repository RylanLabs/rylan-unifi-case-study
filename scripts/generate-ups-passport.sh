#!/usr/bin/env bash
set -euo pipefail

# Description: Power infrastructure monitoring via APC SNMP
# Requires: ups-passport.json
# Consciousness: 2.6
# Runtime: 5

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/inventory/ups-passport.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

# APC UPS targets (SMX3000LV + BVN650M1)
UPS_TARGETS=(
  "10.0.10.20:SMX3000LV"
  "10.0.10.21:BVN650M1"
)
SNMP_COMMUNITY="${SNMP_COMMUNITY:-public}"

UPS_DATA="[]"

for TARGET in "${UPS_TARGETS[@]}"; do
  UPS_IP="${TARGET%%:*}"
  UPS_MODEL="${TARGET##*:}"
  
  # APC MIB OIDs (PowerNet-MIB)
  LOAD=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.4.2.3.0 2>/dev/null | \
    awk -F': ' '{print $2}' | tr -d ' %' || echo "0")
  
  RUNTIME=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.2.2.3.0 2>/dev/null | \
    awk -F': ' '{print $2}' | awk '{print int($1/6000)}' || echo "0")
  
  BATTERY_TEMP=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.2.2.2.0 2>/dev/null | \
    awk -F': ' '{print $2}' | tr -d ' C' || echo "0")
  
  BATTERY_STATUS=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.2.1.1.0 2>/dev/null | \
    awk -F': ' '{print $2}' | sed 's/[^0-9]//g' || echo "1")
  
  BATTERY_REPLACE=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.2.2.4.0 2>/dev/null | \
    awk -F': ' '{print $2}' | sed 's/[^0-9]//g' || echo "1")
  
  INPUT_VOLTAGE=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.3.2.1.0 2>/dev/null | \
    awk -F': ' '{print $2}' | tr -d ' V' || echo "0")
  
  OUTPUT_VOLTAGE=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.4.2.1.0 2>/dev/null | \
    awk -F': ' '{print $2}' | tr -d ' V' || echo "0")
  
  LAST_TEST=$(snmpget -v2c -c "${SNMP_COMMUNITY}" "${UPS_IP}" \
    .1.3.6.1.4.1.318.1.1.1.7.2.3.0 2>/dev/null | \
    awk -F': ' '{print $2}' | tr -d '"' || echo "never")
  
  # Battery status mapping (1=unknown, 2=normal, 3=low, 4=depleted)
  case "${BATTERY_STATUS}" in
    2) STATUS_TEXT="normal" ;;
    3) STATUS_TEXT="low" ;;
    4) STATUS_TEXT="depleted" ;;
    *) STATUS_TEXT="unknown" ;;
  esac
  
  # Battery replacement indicator (1=no, 2=yes)
  REPLACE_TEXT=$([[ "${BATTERY_REPLACE}" == "2" ]] && echo "true" || echo "false")
  
  UPS_DATA=$(echo "${UPS_DATA}" | jq --arg ip "${UPS_IP}" \
    --arg model "${UPS_MODEL}" \
    --arg load "${LOAD}" \
    --arg runtime "${RUNTIME}" \
    --arg temp "${BATTERY_TEMP}" \
    --arg status "${STATUS_TEXT}" \
    --arg replace "${REPLACE_TEXT}" \
    --arg input_v "${INPUT_VOLTAGE}" \
    --arg output_v "${OUTPUT_VOLTAGE}" \
    --arg last_test "${LAST_TEST}" \
    '. += [{
      ip: $ip,
      model: $model,
      load_percent: ($load | tonumber),
      runtime_minutes: ($runtime | tonumber),
      battery_temp_c: ($temp | tonumber),
      battery_status: $status,
      battery_replace_needed: ($replace | test("true")),
      input_voltage: ($input_v | tonumber),
      output_voltage: ($output_v | tonumber),
      last_self_test: $last_test
    }]')
done

cat > "${OUTPUT}" <<EOF
{
  "schema_version": "1.0.0-eternal",
  "generated_at": "${TIMESTAMP}",
  "consciousness": 2.6,
  "ups_devices": ${UPS_DATA},
  "snmp_community": "${SNMP_COMMUNITY}",
  "alert_thresholds": {
    "runtime_minutes_critical": 10,
    "load_percent_warning": 80,
    "battery_temp_c_critical": 35
  },
  "signature": "$(echo -n "${UPS_DATA}" | sha256sum | awk '{print $1}')"
}
EOF

jq empty "${OUTPUT}" || { echo "❌ Invalid JSON"; exit 1; }

# Alert on critical conditions
CRITICAL=$(echo "${UPS_DATA}" | jq '[.[] | select(.runtime_minutes < 10 or .load_percent > 80 or .battery_replace_needed == true)] | length')
[[ "${CRITICAL}" -eq 0 ]] || echo "⚠️  ${CRITICAL} UPS device(s) in critical state"

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(beale): generate ups-passport.json — $(echo "${UPS_DATA}" | jq '. | length') UPS devices monitored" --quiet 2>/dev/null || true

echo "✓ ${OUTPUT}"
