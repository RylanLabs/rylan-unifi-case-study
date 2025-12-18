#!/usr/bin/env bash
# Script: 01_bootstrap/proxmox/lib/metrics-phase.sh
# Purpose: Phase tracking and RTO compliance validation
# Guardian: gatekeeper
# Date: 2025-12-13T06:00:00-06:00
# Consciousness: 4.6

# Sourced by: metrics.sh
# Usage: Source this file; phase metrics functions auto-exported

################################################################################
# METRICS CONFIGURATION
################################################################################

METRICS_FILE="${METRICS_FILE:-/var/log/proxmox-ignite-metrics.json}"
START_TIME="${START_TIME:-$(date +%s)}"

################################################################################
# PHASE METRICS TRACKING
################################################################################

# record_phase_start: Record phase start time in metrics JSON
record_phase_start() {
  local phase_name="$1"
  local phase_start
  phase_start=$(date +%s)

  # Add phase to metrics JSON
  jq --arg phase "$phase_name" \
    --arg start "$phase_start" \
    '.phases[$phase] = {"start": ($start | tonumber), "status": "running"}' \
    "$METRICS_FILE" >"${METRICS_FILE}.tmp" &&
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

  log_info "Phase start recorded: $phase_name"
}

# record_phase_end: Record phase completion and duration
record_phase_end() {
  local phase_name="$1"
  local phase_end
  phase_end=$(date +%s)

  # Update phase completion in metrics JSON
  jq --arg phase "$phase_name" \
    --arg end "$phase_end" \
    '.phases[$phase].end = ($end | tonumber) |
     .phases[$phase].status = "complete" |
     .phases[$phase].duration = (.phases[$phase].end - .phases[$phase].start)' \
    "$METRICS_FILE" >"${METRICS_FILE}.tmp" &&
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

  log_info "Phase end recorded: $phase_name"
}

# record_phase_error: Record phase failure with error message
record_phase_error() {
  local phase_name="$1"
  local error_msg="$2"

  # Mark phase as failed in metrics JSON
  jq --arg phase "$phase_name" \
    --arg error "$error_msg" \
    '.phases[$phase].status = "failed" |
     .phases[$phase].error = $error' \
    "$METRICS_FILE" >"${METRICS_FILE}.tmp" &&
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

  log_info "Phase error recorded: $phase_name - $error_msg"
}

################################################################################
# RTO VALIDATION & COMPLIANCE
################################################################################

# finalize_metrics: Calculate total duration and validate RTO compliance (15 min target)
finalize_metrics() {
  local end_time
  local total_duration
  local rto_minutes
  local target_rto=900 # 15 minutes in seconds
  local compliant

  end_time=$(date +%s)
  total_duration=$((end_time - START_TIME))
  rto_minutes=$(awk "BEGIN {printf \"%.2f\", $total_duration / 60}")
  compliant=$([ $total_duration -le $target_rto ] && echo "true" || echo "false")

  # Update final metrics
  jq --arg end "$(date -Iseconds)" \
    --arg duration "$total_duration" \
    --arg rto_minutes "$rto_minutes" \
    --arg compliant "$compliant" \
    '.ignition_end = $end |
     .total_duration = ($duration | tonumber) |
     .rto_minutes = ($rto_minutes | tonumber) |
     .target_rto = 900 |
     .rto_compliant = ($compliant | fromjson)' \
    "$METRICS_FILE" >"${METRICS_FILE}.tmp" &&
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

  display_metrics_summary "$total_duration" "$rto_minutes" "$compliant"
}

################################################################################
# METRICS DISPLAY & REPORTING
################################################################################

# display_metrics_summary: Print RTO compliance summary and phase breakdown
display_metrics_summary() {
  local total_duration="$1"
  local rto_minutes="$2"
  local compliant="$3"

  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}             IGNITION COMPLETE - METRICS SUMMARY"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  echo "Total Duration: ${total_duration}s (${rto_minutes} minutes)"
  echo "Target RTO:     900s (15 minutes)"
  echo ""

  if [ "$compliant" = "true" ]; then
    echo -e "${GREEN}✅ RTO COMPLIANT${NC}: ${total_duration}s < 900s"
  else
    echo -e "${RED}❌ RTO VIOLATION${NC}: ${total_duration}s > 900s"
  fi

  echo ""
  echo "Phase Breakdown:"

  jq -r '.phases | to_entries[] | "  \(.key): \(.value.duration)s (\(.value.status))"' \
    "$METRICS_FILE" 2>/dev/null || true

  echo ""
  echo "System Information:"
  jq -r '.system | "  CPU Cores: \(.cpu_cores)\n  RAM: \(.ram_gb)GB\n  Disk Free: \(.disk_free_gb)GB\n  Kernel: \(.kernel)"' \
    "$METRICS_FILE" 2>/dev/null || true

  echo ""
  echo "Metrics File: ${METRICS_FILE}"
  echo ""
}

export -f record_phase_start record_phase_end record_phase_error finalize_metrics display_metrics_summary
