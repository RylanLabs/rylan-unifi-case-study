#!/bin/bash
# Ministry of Secrets (Carter) – UniFi API Client v1.0
# Identity: JWT auth, CSRF handling, idempotent calls
set -euo pipefail

# Detect CI (Bauer: Verify Environment)
CI_MODE="${CI:-0}" # GitHub sets CI=true
if [ "$CI_MODE" != "1" ] && [ "$CI_MODE" != "true" ]; then
  # Local: Enforce file perms
  chmod 600 .secrets/* 2>/dev/null || true
fi

UNIFI_IP="192.168.1.13"
UNIFI_API_BASE="https://${UNIFI_IP}/proxy/network/api/s/default"

unifi_login() {
  local temp_file="/tmp/unifi-login-$$.json"

  # Eternal Vault: Carter Hygiene – File or Env Var
  ADMIN_PASS_FILE=".secrets/unifi-admin-pass"
  if [ -f "$ADMIN_PASS_FILE" ] && [ -r "$ADMIN_PASS_FILE" ]; then
    ADMIN_PASS=$(cat "$ADMIN_PASS_FILE")
  elif [ -n "${UNIFI_ADMIN_PASS:-}" ]; then
    ADMIN_PASS="$UNIFI_ADMIN_PASS"
  elif [ -n "${UNIFI_PASS:-}" ]; then
    ADMIN_PASS="$UNIFI_PASS"
  else
    echo "❌ Carter violation: UniFi admin pass missing (file: $ADMIN_PASS_FILE or env: UNIFI_ADMIN_PASS/UNIFI_PASS)" >&2
    exit 1
  fi

  curl -sk -X POST "${UNIFI_IP}/api/auth/login" \
    -d "{\"username\":\"admin\",\"password\":\"$ADMIN_PASS\"}" \
    -c /tmp/unifi-cookies-$$.txt -o "$temp_file"
  JWT_TOKEN=$(grep "TOKEN" /tmp/unifi-cookies-$$.txt | awk '{print $7}')
  JWT_PAYLOAD=$(echo "$JWT_TOKEN" | cut -d'.' -f2)
  PAD=$((4 - ${#JWT_PAYLOAD} % 4))
  JWT_PAYLOAD="${JWT_PAYLOAD}$(printf '=%.0s' $(seq 1 $PAD))"
  CSRF_TOKEN=$(echo "$JWT_PAYLOAD" | base64 -d | jq -r '.csrfToken')
  rm -f "$temp_file" /tmp/unifi-cookies-$$.txt
  [[ -n "$CSRF_TOKEN" ]] || {
    echo "❌ Login failed"
    exit 1
  }
  echo "✅ Authenticated (silent success)"
}

unifi_api_call() {
  local endpoint="$1" method="${2:-GET}" data="${3:-}"
  local temp_file="/tmp/unifi-response-$$.json"
  unifi_login # Idempotent refresh
  curl -sk -b /tmp/unifi-cookies-$$.txt \
    -H "X-CSRF-Token: $CSRF_TOKEN" \
    -X "$method" "${UNIFI_API_BASE}/${endpoint}" \
    ${data:+-d "$data"} -o "$temp_file"
  if grep -q "LoginRequired" "$temp_file"; then
    unifi_login && unifi_api_call "$@" # Auto-retry
  fi
  cat "$temp_file" # Return content (jq downstream)
  rm -f "$temp_file"
}

# Helpers (Idempotent)
unifi_get_devices() { unifi_api_call "stat/device" | jq '.data'; }
unifi_adopt_device() {
  local mac="$1"
  unifi_api_call "cmd/devmgr" POST "{\"mac\":\"$mac\",\"cmd\":\"adopt\"}"
}
unifi_get_networks() { unifi_api_call "rest/networkconf" | jq '.data'; }
unifi_push_network() {
  local config="$1"
  unifi_api_call "rest/networkconf" POST "$config"
}

# Eternal: One-shot execution
echo "🛡️ Carter: Identity provisioned" >&2
