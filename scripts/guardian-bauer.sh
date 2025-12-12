#!/usr/bin/env bash
# Script: guardian-bauer.sh
# Purpose: Summon Bauer to run gatekeeper checks
# Author: Holy Scholar
# Date: 2025-12-11
set -euo pipefail
IFS=$'\n\t'

readonly RESPONSE_FILE="${1:-.github/agents/response.json}"
LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT

if bash gatekeeper.sh >"$LOG_FILE" 2>&1; then
  STATUS="pass"
  MESSAGE="Gatekeeper checks passed"
  EXIT_CODE=0
else
  STATUS="fail"
  MESSAGE="Gatekeeper checks failed"
  EXIT_CODE=1
fi

OUTPUT=$(tail -n 60 "$LOG_FILE" | sed 's/"/\"/g')

jq -n \
  --arg guardian "Bauer" \
  --arg check "gatekeeper" \
  --arg status "$STATUS" \
  --arg message "$MESSAGE" \
  --arg output "$OUTPUT" \
  --arg timestamp "$(date -Iseconds)" \
  '{guardian:$guardian,check:$check,status:$status,message:$message,output:$output,timestamp:$timestamp}' \
  >"$RESPONSE_FILE"

exit "$EXIT_CODE"
