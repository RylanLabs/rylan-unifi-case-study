#!/usr/bin/env bash
# Script: gatekeeper-logger.sh
# Purpose: Canonical structured logging for Gatekeeper pre-push validation
# Guardian: Carter 🔑
# Author: rylanlab canonical
# Date: 2025-12-17
# Ministry: ministry-whispers
# Consciousness: 6.7
set -euo pipefail

GATEKEEPER_LOG_DIR=".audit/gatekeeper"
GATEKEEPER_JSON="${GATEKEEPER_LOG_DIR}/gatekeeper-latest.json"
GATEKEEPER_ROTATING="${GATEKEEPER_LOG_DIR}/gatekeeper.log"

mkdir -p "$GATEKEEPER_LOG_DIR"

declare -A PUSH_METADATA
declare -A VALIDATORS

log_push_start() {
  local branch="$1"
  local commit_hash="$2"
  local commit_message="${3:-}"

  PUSH_METADATA[timestamp]=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  PUSH_METADATA[branch]="$branch"
  PUSH_METADATA[commit_hash]="$commit_hash"
  PUSH_METADATA[commit_message]="$commit_message"
  PUSH_METADATA[push_result]="PENDING"

  VALIDATORS=()

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] PUSH START: $branch ($commit_hash)" >> "$GATEKEEPER_ROTATING"
}

log_validator() {
  local validator_name="$1"
  local status="$2"
  local duration_ms="$3"
  local error_message="${4:-}"

  local validator_json="{\"status\":\"$status\",\"duration_ms\":$duration_ms"

  if [[ -n "$error_message" ]]; then
    error_message=$(echo "$error_message" | sed 's/"/\\"/g')
    validator_json+=",\"error\":\"$error_message\""
  fi

  validator_json+="}"

  VALIDATORS["$validator_name"]="$validator_json"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] VALIDATOR: $validator_name = $status (${duration_ms}ms)" >> "$GATEKEEPER_ROTATING"
}

log_push_end() {
  local result="$1"
  local recommendation="${2:-}"

  PUSH_METADATA[push_result]="$result"

  local validators_json="{"
  local first=true
  for validator in "${!VALIDATORS[@]}"; do
    if [[ "$first" == true ]]; then
      validators_json+="\"$validator\":${VALIDATORS[$validator]}"
      first=false
    else
      validators_json+=",\"$validator\":${VALIDATORS[$validator]}"
    fi
  done
  validators_json+="}"

  local commit_msg=$(echo "${PUSH_METADATA[commit_message]}" | sed 's/"/\\"/g')

  local final_json="{"
  final_json+="\"timestamp\":\"${PUSH_METADATA[timestamp]}\","
  final_json+="\"branch\":\"${PUSH_METADATA[branch]}\","
  final_json+="\"commit_hash\":\"${PUSH_METADATA[commit_hash]}\","
  final_json+="\"commit_message\":\"$commit_msg\","
  final_json+="\"push_result\":\"$result\","
  final_json+="\"validators\":$validators_json"

  if [[ -n "$recommendation" ]]; then
    recommendation=$(echo "$recommendation" | sed 's/"/\\"/g')
    final_json+=",\"recommendation\":\"$recommendation\""
  fi

  final_json+="}"

  echo "$final_json" | jq '.' > "$GATEKEEPER_JSON" 2>/dev/null || echo "$final_json" > "$GATEKEEPER_JSON"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] PUSH END: $result" >> "$GATEKEEPER_ROTATING"
  echo "---" >> "$GATEKEEPER_ROTATING"

  rotate_logs
}

rotate_logs() {
  local max_size=$((5 * 1024 * 1024))  # 5MB

  [[ -f "$GATEKEEPER_ROTATING" ]] || return 0

  local current_size
  if command -v stat >/dev/null; then
    if [[ "$OSTYPE" == darwin* ]]; then
      current_size=$(stat -f%z "$GATEKEEPER_ROTATING")
    else
      current_size=$(stat -c%s "$GATEKEEPER_ROTATING")
    fi
  else
    current_size=$(wc -c < "$GATEKEEPER_ROTATING")
  fi

  if [[ $current_size -gt $max_size ]]; then
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mv "$GATEKEEPER_ROTATING" "${GATEKEEPER_LOG_DIR}/gatekeeper-${timestamp}.log"
    gzip "${GATEKEEPER_LOG_DIR}/gatekeeper-${timestamp}.log" || true

    ls -t "${GATEKEEPER_LOG_DIR}"/gatekeeper-*.log.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
  fi
}

ensure_gk_dir() { mkdir -p "$GATEKEEPER_LOG_DIR"; }

export -f log_push_start log_validator log_push_end rotate_logs ensure_gk_dir
