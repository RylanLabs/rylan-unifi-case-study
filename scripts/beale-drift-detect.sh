#!/usr/bin/env bash
# Script: beale-drift-detect.sh
# Purpose: Detect configuration drift for summon workflow
# Author: Beale the Watcher
# Date: 2025-12-11
set -euo pipefail
IFS=$'\n\t'

readonly RESPONSE_FILE="${1:-.github/agents/response.json}"
DRIFT=false
DETAILS=()

check_port_22() {
  if grep -r "Port 22" scripts/ 02-declarative-config/ app/ 2>/dev/null | head -3; then
    DETAILS+=("Default SSH port (22) referenced in configs")
    DRIFT=true
  fi
}

check_vlan_ips() {
  if grep -rE "10\\.0\\.(10|30|40|90)\\.[0-9]+" scripts/ --include="*.sh" 2>/dev/null | grep -v "# Expected" | head -3; then
    DETAILS+=("Hardcoded VLAN IPs detected in scripts")
    DRIFT=true
  fi
}

check_firewall_rule_count() {
  if [[ -f 02-declarative-config/policy-table.yaml ]]; then
    local count
    count=$(grep -c "^  - " 02-declarative-config/policy-table.yaml 2>/dev/null || echo "0")
    if [[ "$count" -gt 10 ]]; then
      DETAILS+=("Firewall rules exceed Hellodeolu limit (${count} > 10)")
      DRIFT=true
    fi
  fi
}

check_credentials() {
  if grep -rE "(password|secret)\\s*=\\s*['\"][^'\"]+['\"]" --include="*.py" --include="*.sh" app/ scripts/ 2>/dev/null | grep -v ".pyc" | head -3; then
    DETAILS+=("Potential hardcoded credentials detected")
    DRIFT=true
  fi
}

check_port_22
check_vlan_ips
check_firewall_rule_count
check_credentials

if [[ "$DRIFT" == true ]]; then
  jq -n \
    --argjson details "$(printf '%s\n' "${DETAILS[@]}" | jq -R . | jq -s .)" \
    --arg timestamp "$(date -Iseconds)" \
    '{guardian:"Beale", scan_type:"drift_detection", severity:"high", drift_detected:true, details:$details, timestamp:$timestamp, remediation:"Review flagged configs and update baselines"}' \
    >"$RESPONSE_FILE"
  exit 1
else
  jq -n \
    --arg timestamp "$(date -Iseconds)" \
    '{guardian:"Beale", scan_type:"drift_detection", severity:"none", drift_detected:false, message:"No drift detected. Fortress stable.", timestamp:$timestamp}' \
    >"$RESPONSE_FILE"
fi
