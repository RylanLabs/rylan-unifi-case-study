#!/usr/bin/env bash
set -euo pipefail

RESPONSE="${1:-/tmp/veil.json}"
LOG_INPUT="${2:-}"

if [[ -n "$LOG_INPUT" ]]; then
  DIAG=$(echo "$LOG_INPUT" | grep -iE 'failed|error' | head -5 || true)
  jq -n --arg d "$DIAG" '{guardian:"Veil",diagnosis:"Common CI failure patterns detected",details:$d}' > "$RESPONSE"
else
  jq -n '{guardian:"Veil",message:"Paste failing CI log after @Veil Diagnose"}' > "$RESPONSE"
fi
