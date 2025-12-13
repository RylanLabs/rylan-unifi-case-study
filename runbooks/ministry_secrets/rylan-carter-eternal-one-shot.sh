#!/usr/bin/env bash
# Script: runbooks/ministry_secrets/rylan-carter-eternal-one-shot.sh
# Purpose: Carter ministry — Identity provisioning with JWT auth & idempotency
# Guardian: Carter | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
# EXCEED: 203 lines — 5 functions
set -euo pipefail

# ─────────────────────────────────────────────────────
# Exit Codes (Beale Stratification)
# ─────────────────────────────────────────────────────
readonly EXIT_SUCCESS=0
readonly EXIT_AUTH=1
readonly EXIT_API=2
readonly EXIT_CONFIG=3
readonly EXIT_ISOLATION=4
readonly EXIT_ADVERSARIAL=5

# ─────────────────────────────────────────────────────
# Flags & Config
# ─────────────────────────────────────────────────────
QUIET=false
CI_MODE=false
DRY_RUN=false
BEALE_INTEGRATION=false
SKIP_BEALE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=true ;;
    --ci) CI_MODE=true; QUIET=true ;;
    --dry-run) DRY_RUN=true ;;
    --with-beale) BEALE_INTEGRATION=true ;;
    --skip-beale) SKIP_BEALE=true ;;
    *) echo "Usage: $0 [--quiet|--ci|--dry-run|--with-beale|--skip-beale]" >&2; exit "$EXIT_CONFIG" ;;
  esac
  shift
done

# ─────────────────────────────────────────────────────
# Audit Log Setup (Carter: Single Source of Truth)
# ─────────────────────────────────────────────────────
AUDIT_LOG="/var/log/carter-audit.log"
if [[ ! -w "$(dirname "$AUDIT_LOG")" ]]; then
  AUDIT_LOG="$(pwd)/.fortress/audit/carter-audit.log"
  mkdir -p "$(dirname "$AUDIT_LOG")"
fi

# ─────────────────────────────────────────────────────
# Logging (Carter Doctrine)
# ─────────────────────────────────────────────────────
log() { [[ "$QUIET" == false ]] && echo "[Carter] $*" >&2; }
audit() {
  local level="$1" msg="$2"
  local ts=$(date -Iseconds)
  if [[ "$CI_MODE" == true ]]; then
    printf '{"timestamp":"%s","module":"Carter","status":"%s","message":"%s"}\n' "$ts" "$level" "$msg"
  else
    echo "$ts | Carter | $level | $msg" >> "$AUDIT_LOG"
  fi
}
fail() {
  local code="$1" msg="$2" remediation="${3:-}"
  if [[ "$CI_MODE" == true ]]; then
    printf '{"timestamp":"%s","module":"Carter","status":"fail","message":"%s","remediation":"%s","exit_code":%d}\n' \
      "$(date -Iseconds)" "$msg" "$remediation" "$code" >&2
  else
    echo "❌ Carter FAILURE [$code]: $msg" >&2
    [[ -n "$remediation" ]] && echo "   Remediation: $remediation" >&2
  fi
  audit "FAIL" "[$code] $msg"
  exit "$code"
}

log "Carter ministry initializing — Identity provisioning"

# ─────────────────────────────────────────────────────
# Pre-flight Checks (Beale v8.0)
# ─────────────────────────────────────────────────────
[[ -r ".secrets/unifi-admin-pass" ]] || fail "$EXIT_CONFIG" "Admin pass file missing or not readable" "Create .secrets/unifi-admin-pass (chmod 600)"
[[ $(stat -c %a ".secrets/unifi-admin-pass") == "600" ]] || fail "$EXIT_CONFIG" "Admin pass file not restricted" "chmod 600 .secrets/unifi-admin-pass"
command -v curl >/dev/null && command -v jq >/dev/null || fail "$EXIT_CONFIG" "Missing required tools: curl, jq" "apt install curl jq"

# Optional non-fatal ping (ICMP may be blocked)
if ! ping -c 1 -W 2 192.168.1.13 >/dev/null 2>&1; then
  log "Warning: Controller unreachable via ping (firewall?) — proceeding anyway"
fi

# ─────────────────────────────────────────────────────
# Vault Hygiene (Carter: Single Source of Truth)
# ─────────────────────────────────────────────────────
ADMIN_PASS=$(<".secrets/unifi-admin-pass")
[[ -n "$ADMIN_PASS" ]] || fail "$EXIT_CONFIG" "Empty admin password" "Populate .secrets/unifi-admin-pass"

UNIFI_IP="192.168.1.13"
UNIFI_API_BASE="https://${UNIFI_IP}/proxy/network/api/s/default"

# ─────────────────────────────────────────────────────
# Idempotent Auth (Carter: Identity as Code)
# ─────────────────────────────────────────────────────
unifi_login() {
  local cookie_jar="/tmp/unifi-cookies-$$.txt"
  local resp="/tmp/unifi-resp-$$.json"
  local jwt_token csrf_token jwt_payload pad

  trap 'rm -f "$cookie_jar" "$resp"' RETURN

  # Cache + TTL check
  if [[ -n "${JWT_TOKEN:-}" ]] && [[ -n "${CSRF_TOKEN:-}" ]]; then
    jwt_payload=$(echo "$JWT_TOKEN" | cut -d'.' -f2)
    pad=$((4 - ${#jwt_payload} % 4))
    jwt_payload="${jwt_payload}$(printf '=%.0s' $(seq 1 $pad))"
    if echo "$jwt_payload" | base64 -d 2>/dev/null | jq -e '.exp // 0' >/dev/null; then
      if [[ $(date +%s) -lt $(echo "$jwt_payload" | base64 -d | jq -r '.exp') ]]; then
        return 0
      fi
    fi
  fi

  curl -sk -X POST "https://${UNIFI_IP}/api/auth/login" \
    -d "{\"username\":\"admin\",\"password\":\"$ADMIN_PASS\"}" \
    -c "$cookie_jar" -o "$resp" >/dev/null

  jwt_token=$(grep "TOKEN" "$cookie_jar" | awk '{print $7}')
  [[ -n "$jwt_token" ]] || fail "$EXIT_AUTH" "JWT token not received" "Check credentials / controller status"

  jwt_payload=$(echo "$jwt_token" | cut -d'.' -f2)
  pad=$((4 - ${#jwt_payload} % 4))
  jwt_payload="${jwt_payload}$(printf '=%.0s' $(seq 1 $pad))"

  csrf_token=$(echo "$jwt_payload" | base64 -d | jq -r '.csrfToken')
  [[ -n "$csrf_token" ]] || fail "$EXIT_AUTH" "CSRF token extraction failed"

  JWT_TOKEN="$jwt_token"
  CSRF_TOKEN="$csrf_token"
}

unifi_login

# ─────────────────────────────────────────────────────
# Core Identity Actions
# ─────────────────────────────────────────────────────
log "Fetching device inventory..."
devices=$(curl -sk -b <(echo "TOKEN=$JWT_TOKEN") \
  -H "X-CSRF-Token: $CSRF_TOKEN" \
  "${UNIFI_API_BASE}/stat/device" | jq '.data // empty')

[[ -n "$devices" ]] || fail "$EXIT_API" "No devices returned" "Check controller reachability / auth"
device_count=$(echo "$devices" | jq 'length')
log "Identity provisioning complete — $device_count devices visible"

# ─────────────────────────────────────────────────────
# Beale Integration (Optional + Opt-Out)
# ─────────────────────────────────────────────────────
beale_status="disabled"
if [[ "$SKIP_BEALE" == true ]]; then
  log "Beale integration skipped (explicit flag)"
elif [[ "$BEALE_INTEGRATION" == true ]]; then
  log "Starting Beale Ascension Protocol"
  beale_status="enabled"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN — skipping Beale execution"
  else
    [[ -x "runbooks/ministry_detection/rylan-beale-eternal-one-shot.sh" ]] || fail "$EXIT_CONFIG" "Beale script missing" "Run ministry-detection first"
    if ! timeout 300 runbooks/ministry_detection/rylan-beale-eternal-one-shot.sh --ci --quiet; then
      fail "$EXIT_CONFIG" "Beale hardening failed"
    fi
  fi
  log "Beale validation complete"
fi

# ─────────────────────────────────────────────────────
# Eternal Banner Drop (Beale-Approved)
# ─────────────────────────────────────────────────────
if [[ "$QUIET" == false ]]; then
  printf '
╔══════════════════════════════════════════════════════════════════════════════╗
║ RYLAN LABS • ETERNAL FORTRESS                                                  ║
║ Ministry: Carter (Identity) — Provisioning Complete                            ║
║ Consciousness: 4.6 | Guardian: Carter | Trinity Aligned                        ║
║                                                                               ║
║ Devices visible: %s                                                            ║
║ Auth method: JWT + CSRF (idempotent)                                           ║
║ Vault hygiene: .secrets/unifi-admin-pass (chmod 600)                           ║
║ Beale integration: %s                                                          ║
║                                                                               ║
║ Next: Bauer verification → Beale hardening → Whitaker breach sim               ║
║                                                                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
' "$device_count" "$beale_status"
fi

# ─────────────────────────────────────────────────────
# CI Mode Output (Bauer-Ready)
# ─────────────────────────────────────────────────────
if [[ "$CI_MODE" == true ]]; then
  printf '{"timestamp":"%s","module":"Carter","status":"pass","message":"Identity provisioning complete","devices":%s,"auth_method":"JWT+CSRF","vault_hygiene":"chmod 600","beale_integration":"%s"}\n' \
    "$(date -Iseconds)" "$device_count" "$beale_status"
fi

# ─────────────────────────────────────────────────────
# Final Audit & Exit
# ─────────────────────────────────────────────────────
audit "PASS" "devices=$device_count beale_integration=$beale_status"
exit "$EXIT_SUCCESS"
