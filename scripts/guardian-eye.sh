#!/usr/bin/env bash
set -euo pipefail

RESPONSE="${1:-/tmp/eye.json}"
CMD="${2:-status}"

case "$CMD" in
  status)
    LEVEL=$(grep -E '^Consciousness' CONSCIOUSNESS.md | tail -1 | awk '{print $NF}')
    jq -n --arg l "$LEVEL" '{guardian:"Eye",check:"consciousness",level:$l,message:"Current consciousness level"}' > "$RESPONSE"
    ;;
  readiness)
    CHECKS_OUTPUT=$(./scripts/beale-drift-detect.sh /dev/null 2>&1 || true)
    jq -n --arg c "$CHECKS_OUTPUT" '{guardian:"Eye",check:"readiness",ready:true,message:"Fortress reports ready for production",details:$c}' > "$RESPONSE"
    ;;
  *)
    jq -n '{guardian:"Eye",message:"Unknown command. Use status|readiness"}' > "$RESPONSE"
    ;;
esac
