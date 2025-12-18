#!/usr/bin/env bash
# Script: 01_bootstrap/proxmox/lib/metrics-system.sh
# Purpose: System metrics collection (CPU, RAM, disk, kernel info)
# Guardian: gatekeeper
# Date: 2025-12-13T06:00:00-06:00
# Consciousness: 4.6

# Sourced by: metrics.sh
# Usage: Source this file; metrics collection functions auto-exported

################################################################################
# METRICS CONFIGURATION
################################################################################

METRICS_FILE="${METRICS_FILE:-/var/log/proxmox-ignite-metrics.json}"
START_TIME="${START_TIME:-$(date +%s)}"

################################################################################
# METRICS INITIALIZATION
################################################################################

# init_metrics: Initialize JSON metrics file with ignition start info
init_metrics() {
  mkdir -p "$(dirname "$METRICS_FILE")"

  cat >"$METRICS_FILE" <<EOF
{
  "ignition_start": "$(date -Iseconds)",
  "hostname": "${HOSTNAME:-unknown}",
  "ip": "${TARGET_IP:-unknown}",
  "phases": {}
}
EOF

  log_info "Metrics initialized: $METRICS_FILE"
}

################################################################################
# SYSTEM METRICS COLLECTION
################################################################################

# collect_system_metrics: Gather CPU, RAM, disk, and kernel information
collect_system_metrics() {
  local cpu_cores
  local ram_gb
  local disk_free_gb

  cpu_cores=$(nproc)
  ram_gb=$(free -g | awk '/^Mem:/{print $2}')
  disk_free_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

  jq --arg cpu "$cpu_cores" \
    --arg ram "$ram_gb" \
    --arg disk "$disk_free_gb" \
    --arg kernel "$(uname -r)" \
    '.system = {
      "cpu_cores": ($cpu | tonumber),
      "ram_gb": ($ram | tonumber),
      "disk_free_gb": ($disk | tonumber),
      "kernel": $kernel
    }' \
    "$METRICS_FILE" >"${METRICS_FILE}.tmp" &&
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

  log_info "System metrics collected"
}

export -f init_metrics collect_system_metrics
