# shellcheck shell=bash
#
# lib/metrics.sh - Real-time metrics and telemetry tracking
# JSON output for RTO compliance and performance analysis
#
# Sourced by: orchestrator and phase scripts
# NOTE: No shebang or set -euo pipefail (sourced file, not executed)

################################################################################
# METRICS CONFIGURATION
################################################################################

METRICS_FILE="/var/log/proxmox-ignite-metrics.json"
START_TIME=$(date +%s)

################################################################################
# METRICS INITIALIZATION
################################################################################

init_metrics() {
  mkdir -p "$(dirname "$METRICS_FILE")"
  
  cat > "$METRICS_FILE" <<EOF
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
# PHASE METRICS TRACKING
################################################################################

record_phase_start() {
  local phase_name="$1"
  local phase_start
  phase_start=$(date +%s)
  
  # Add phase to metrics JSON
  jq --arg phase "$phase_name" \
     --arg start "$phase_start" \
    '.phases[$phase] = {"start": ($start | tonumber), "status": "running"}' \
    "$METRICS_FILE" > "${METRICS_FILE}.tmp" && \
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
  
  log_info "Phase start recorded: $phase_name"
}

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
    "$METRICS_FILE" > "${METRICS_FILE}.tmp" && \
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
  
  log_info "Phase end recorded: $phase_name"
}

record_phase_error() {
  local phase_name="$1"
  local error_msg="$2"
  
  # Mark phase as failed in metrics JSON
  jq --arg phase "$phase_name" \
     --arg error "$error_msg" \
    '.phases[$phase].status = "failed" | 
     .phases[$phase].error = $error' \
    "$METRICS_FILE" > "${METRICS_FILE}.tmp" && \
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
  
  log_info "Phase error recorded: $phase_name - $error_msg"
}

################################################################################
# SYSTEM METRICS COLLECTION
################################################################################

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
    "$METRICS_FILE" > "${METRICS_FILE}.tmp" && \
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
  
  log_info "System metrics collected"
}

################################################################################
# RTO VALIDATION & COMPLIANCE
################################################################################

finalize_metrics() {
  local end_time
  local total_duration
  local rto_minutes
  local target_rto=900  # 15 minutes in seconds
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
    "$METRICS_FILE" > "${METRICS_FILE}.tmp" && \
    mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
  
  display_metrics_summary "$total_duration" "$rto_minutes" "$compliant"
}

################################################################################
# METRICS DISPLAY & REPORTING
################################################################################

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

# Export for use in parent shell
export -f init_metrics record_phase_start record_phase_end record_phase_error
export -f collect_system_metrics finalize_metrics display_metrics_summary
