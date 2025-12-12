#!/usr/bin/env bash
# Script: guardian-carter.sh
# Purpose: Summon Carter to dry-run onboarding
# Author: Holy Scholar
# Date: 2025-12-11
set -euo pipefail
IFS=$'\n\t'

readonly EMAIL="${1:-}"
readonly RESPONSE_FILE="${2:-.github/agents/response.json}"
LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT

validate_email() {
  [[ -n "$EMAIL" ]] || return 1
  [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@rylan\.internal$ ]]
}

emit_error() {
  local message="$1"
  jq -n \
    --arg guardian "Carter" \
    --arg status "error" \
    --arg message "$message" \
    --arg timestamp "$(date -Iseconds)" \
    '{guardian:$guardian,status:$status,message:$message,timestamp:$timestamp}' \
    >"$RESPONSE_FILE"
  exit 1
}

validate_email || emit_error "Invalid or missing email (expected user@rylan.internal)"

if DRY_RUN=1 bash runbooks/ministry-secrets/onboard.sh "$EMAIL" >"$LOG_FILE" 2>&1; then
  STATUS="success"
  MESSAGE="Onboard dry-run completed"
  EXIT_CODE=0
else
  STATUS="error"
  MESSAGE="Onboard dry-run failed"
  EXIT_CODE=1
fi

OUTPUT=$(tail -n 40 "$LOG_FILE" | sed 's/"/\"/g')

jq -n \
  --arg guardian "Carter" \
  --arg status "$STATUS" \
  --arg email "$EMAIL" \
  --arg message "$MESSAGE" \
  --arg output "$OUTPUT" \
  --arg timestamp "$(date -Iseconds)" \
  '{guardian:$guardian,status:$status,email:$email,message:$message,output:$output,timestamp:$timestamp}' \
  >"$RESPONSE_FILE"

exit "$EXIT_CODE"
