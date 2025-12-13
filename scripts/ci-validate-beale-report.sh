#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/ci-validate-beale-report.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# CI validator: ensure beale-report-*.json exists and contains required keys
# Small, fast, exits non-zero on failure

REPORT=$(ls -1t beale-report-*.json 2>/dev/null | head -n1 || true)
if [[ -z "$REPORT" ]]; then
  echo "ERROR: no beale-report-*.json found"
  exit 2
fi

# Required keys
REQUIRED=(timestamp duration_seconds consciousness guardian firewall_rules vlan_isolated ssh_hardened services_running status)

if command -v jq &>/dev/null; then
  for k in "${REQUIRED[@]}"; do
    if ! jq -e "has(\"$k\")" "$REPORT" >/dev/null; then
      echo "ERROR: report missing key: $k"
      jq '.' "$REPORT" || true
      exit 3
    fi
  done
else
  # Fallback to python parser
  python3 - <<PY
import json,sys
r=json.load(open('$REPORT'))
for k in ${REQUIRED[@]}:
    if k not in r:
        print('ERROR: report missing key:',k)
        sys.exit(3)
print('OK')
PY
fi

echo "Beale report validation passed: $REPORT"
exit 0
