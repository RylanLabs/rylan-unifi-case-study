#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/network.sh
# Purpose: Network interface detection and utilities
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6

# Sourced by: common.sh
# Usage: Source this file; network functions auto-exported

################################################################################
# NETWORK UTILITIES
################################################################################

# detect_primary_interface: Auto-detect primary network interface
detect_primary_interface() {
  # Find interface with default route
  local primary_if
  primary_if=$(ip route | grep default | awk '{print $5}' | head -n1)

  if [ -z "$primary_if" ]; then
    # Fallback: First non-loopback interface that's UP
    primary_if=$(ip link show | grep -v "lo:" | grep "state UP" | head -n1 | awk -F: '{print $2}' | xargs)
  fi

  if [ -z "$primary_if" ]; then
    fail_with_context 101 "No network interface detected" \
      "Verify physical network cable is connected"
  fi

  echo "$primary_if"
}

export -f detect_primary_interface
