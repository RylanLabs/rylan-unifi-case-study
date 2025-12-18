#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/log.sh
# Purpose: Logging and phase output utilities
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6
# EXCEED: 35 lines — 5 functions

# Sourced by: common.sh
# Usage: Source this file; functions auto-exported to parent shell

################################################################################
# LOGGING FUNCTIONS
################################################################################

# log_info: Print informational message
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# log_success: Print success message (green)
log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# log_warn: Print warning message (yellow)
log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# log_error: Print error message (red)
log_error() {
  echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# phase_start: Print prominent phase header
phase_start() {
  local phase_num="$1"
  local phase_name="$2"
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC} Phase ${phase_num}: ${phase_name}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  log_info "Phase ${phase_num}: ${phase_name}"
}

export -f log_info log_success log_warn log_error phase_start
