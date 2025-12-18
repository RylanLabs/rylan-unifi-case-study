#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/validate.sh
# Purpose: Validation helpers for prerequisites, permissions, and network formats
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6

# Sourced by: common.sh
# Usage: Source this file; validation functions auto-exported

################################################################################
# VALIDATION HELPERS
################################################################################

# validate_root: Ensure script is running as root
validate_root() {
  if [ "$EUID" -ne 0 ]; then
    fail_with_context 1 "This script must be run as root" \
      "Run: sudo $0"
  fi
}

# validate_prerequisite_command: Check if command exists
validate_prerequisite_command() {
  local cmd="$1"

  if ! command -v "$cmd" &>/dev/null; then
    fail_with_context 2 "Required command not found: $cmd" \
      "Install via: apt-get install $cmd"
  fi
}

# validate_ip_format: Check if IP address is valid
validate_ip_format() {
  local ip="$1"
  local ip_only="${ip%/*}"

  if ! echo "$ip_only" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
    return 1
  fi

  return 0
}

# validate_cidr_format: Check if CIDR notation is valid
validate_cidr_format() {
  local cidr="$1"

  if ! echo "$cidr" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$'; then
    return 1
  fi

  return 0
}

export -f validate_root validate_prerequisite_command validate_ip_format validate_cidr_format
