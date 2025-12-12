#!/usr/bin/env bash
set -euo pipefail

RESPONSE="${1:-/tmp/gatekeeper.json}"

pre-commit run --all-files > /tmp/gate.log 2>&1 || true

if grep -q "Failed" /tmp/gate.log; then
  jq -n \
    --arg out "$(cat /tmp/gate.log)" \
    '{guardian:"Gatekeeper",status:"fail",message:"Pre-commit failed",details:$out}' > "$RESPONSE"
  exit 1
else
  jq -n '{guardian:"Gatekeeper",status:"pass",message:"Gate passed – fortress green"}' > "$RESPONSE"
fi
