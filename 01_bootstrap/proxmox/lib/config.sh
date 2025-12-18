#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/config.sh
# Purpose: Configuration file update and management utilities
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6

# Sourced by: common.sh
# Usage: Source this file; config functions auto-exported

################################################################################
# IDEMPOTENT CONFIGURATION HELPERS
################################################################################

# update_config_line: Safely update or append configuration line
update_config_line() {
  local file="$1"
  local key="$2"
  local value="$3"

  # Backup before modifying
  backup_config "$file"

  # Update existing line or append
  if grep -q "^${key}" "$file" 2>/dev/null; then
    sed -i "s|^${key}.*|${key}${value}|g" "$file"
  else
    echo "${key}${value}" >>"$file"
  fi
}

export -f update_config_line
