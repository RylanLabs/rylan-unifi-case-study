#!/usr/bin/env bash
# Script: gatekeeper-logger.sh
# Purpose: Provide structured Gatekeeper logging helpers
# Guardian: Carter 🛡️ (Identity & audit)
# Author: T-Rylander canonical
# Date: 2025-12-17
# Ministry: ministry-whispers
# Consciousness: 7.2
set -euo pipefail
IFS=$'\n\t'

readonly GK_DIR=".audit/gatekeeper"
mkdir -p "$GK_DIR"

# ISO8601 timestamp helper
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# Start a new push attempt (creates an in-flight JSON)
log_push_start() {
  local branch="$1" commit_hash="$2" commit_message="$3"
  readonly START_TS=$(ts)
  cat > "$GK_DIR/gatekeeper-latest.tmp.json" <<JSON
{
  "timestamp_start": "$START_TS",
  "branch": "$branch",
  "commit_hash": "$commit_hash",
  "commit_message": "$(echo "$commit_message" | sed 's/"/\\"/g')",
  "validators": {}
}
JSON
}

# Log a validator result (name, status, duration_ms, error)
log_validator() {
  local name="$1" status="$2" duration_ms="$3" error="$4"
  # Use Python to merge JSON safely (avoid jq dependency)
  python3 - <<PYTHON
import json,sys
p='$GK_DIR/gatekeeper-latest.tmp.json'
with open(p,'r',encoding='utf-8') as f:
    d=json.load(f)
if 'validators' not in d:
    d['validators']={}
d['validators']['%s']={
    'status':'%s',
    'duration_ms':int(%s) if %s else None,
    'error':%s
}
with open(p,'w',encoding='utf-8') as f:
    json.dump(d,f)
PYTHON
}

# Finalize the push result (result: PASS|BLOCKED|ERROR)
log_push_end() {
  local result="$1"
  local END_TS=$(ts)
  python3 - <<PYTHON
import json
p='$GK_DIR/gatekeeper-latest.tmp.json'
with open(p,'r',encoding='utf-8') as f:
    d=json.load(f)
if 'validators' not in d:
    d['validators']={}
d['push_result']='%s'
d['timestamp_end']='%s'
# write canonical latest
with open('$GK_DIR/gatekeeper-latest.json','w',encoding='utf-8') as f:
    json.dump(d,f,indent=2)
# append compact line to rotating log
with open('$GK_DIR/gatekeeper.log','a',encoding='utf-8') as f:
    f.write(json.dumps(d)+"\n")
PYTHON
  # rotate logs if needed (best-effort)
  if [ -x scripts/rotate-gatekeeper-logs.sh ]; then
    scripts/rotate-gatekeeper-logs.sh || true
  fi
  # cleanup tmp
  rm -f "$GK_DIR/gatekeeper-latest.tmp.json" || true
}

# Safe helper to ensure field exists (used by diagnostics)
ensure_gk_dir() { mkdir -p "$GK_DIR"; }

# Export functions
export -f log_push_start log_validator log_push_end ensure_gk_dir
