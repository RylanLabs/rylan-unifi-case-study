#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/retry.sh
# Purpose: Retry logic with exponential backoff and timing utilities
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6

# Sourced by: common.sh
# Usage: Source this file; retry and timing functions auto-exported

################################################################################
# RETRY LOGIC WITH EXPONENTIAL BACKOFF
################################################################################

# retry_cmd: Execute command with retry and exponential backoff
retry_cmd() {
  local max_attempts="${1}"
  local delay="${2}"
  shift 2
  local cmd="$*"
  local attempt=1

  while [ $attempt -le "$max_attempts" ]; do
    log_info "Attempt ${attempt}/${max_attempts}: ${cmd}"

    if eval "$cmd"; then
      return 0
    fi

    if [ $attempt -lt "$max_attempts" ]; then
      log_warn "Command failed, retrying in ${delay}s..."
      sleep "$delay"
      delay=$((delay * 2)) # Exponential backoff
    fi

    attempt=$((attempt + 1))
  done

  fail_with_context 99 "Command failed after ${max_attempts} attempts: ${cmd}" \
    "Check network connectivity and try again"
}

# elapsed_time: Calculate time elapsed between two timestamps
elapsed_time() {
  local start="$1"
  local end="$2"
  local elapsed
  elapsed=$((end - start))

  local minutes
  minutes=$((elapsed / 60))
  local seconds
  seconds=$((elapsed % 60))

  printf "%02d:%02d" "$minutes" "$seconds"
}

export -f retry_cmd elapsed_time
