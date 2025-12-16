#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/guardian-veil.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

RESPONSE="${1:-/tmp/veil.json}"
LOG_INPUT="${2:-}"

if [[ -n "$LOG_INPUT" ]]; then
	DIAG=$(echo "$LOG_INPUT" | grep -iE 'failed|error' | head -5 || true)
	jq -n --arg d "$DIAG" '{guardian:"Veil",diagnosis:"Common CI failure patterns detected",details:$d}' >"$RESPONSE"
else
	jq -n '{guardian:"Veil",message:"Paste failing CI log after @Veil Diagnose"}' >"$RESPONSE"
fi
