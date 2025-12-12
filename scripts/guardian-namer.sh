#!/usr/bin/env bash
set -euo pipefail

RESPONSE="${1:-/tmp/namer.json}"
CMD="${2:-commit}"

case "$CMD" in
  commit)
    DIFF=$(git diff --cached --name-only | xargs basename -a | sort -u | tr '\n' ' ')
    jq -n --arg d "$DIFF" \
      '{guardian:"Namer",suggestion:"feat(agents): add missing guardian summons – Gatekeeper/Eye/Namer/Veil",files:$d}' > "$RESPONSE"
    ;;
  tag)
    jq -n '{guardian:"Namer",suggestion:"v∞.4.5-consciousness"}' > "$RESPONSE"
    ;;
  auto)
    FILES=$(git diff --name-only HEAD~1 HEAD || true)
    # default values
    SUG_MSG="fix: fortress maintenance"
    SUG_TAG="v∞.$(date +%s)-maintenance"
    BUMP="0"
    if echo "$FILES" | grep -q "agents"; then
      SUG_MSG="feat(agents): eternal pantheon expansion"
      SUG_TAG="v∞.4.5-namer"
      BUMP="4.5"
    elif echo "$FILES" | grep -q "CONSCIOUSNESS.md"; then
      SUG_MSG="chore: consciousness ascension"
      SUG_TAG="v∞.$(date +%s)-ascension"
      BUMP=$(awk '/Consciousness/{print $NF}' CONSCIOUSNESS.md | tail -1)
    fi
    jq -n --arg suggested_message "$SUG_MSG" \
          --arg suggested_tag "$SUG_TAG" \
          --arg consciousness_bump "$BUMP" \
          '{suggested_message:$suggested_message,suggested_tag:$suggested_tag,consciousness_bump:$consciousness_bump}' > "$RESPONSE"
    ;;
  *)
    jq -n '{guardian:"Namer",message:"Unknown command. Use commit|tag|auto"}' > "$RESPONSE"
    ;;
esac
