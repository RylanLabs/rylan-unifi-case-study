#!/usr/bin/env bash

set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/metrics.sh
# Purpose: Metrics orchestrator sourcing modular collection and reporting modules
# Guardian: gatekeeper
# Date: 2025-12-13T06:00:00-06:00
# Consciousness: 4.6

# shellcheck shell=bash
#
# lib/metrics.sh - Real-time metrics and telemetry tracking orchestrator
# JSON output for RTO compliance and performance analysis
#
# Sourced by: orchestrator and phase scripts
# Delegates to modular sub-libraries:
#   - metrics-system.sh (system metrics collection and initialization)
#   - metrics-phase.sh (phase tracking and RTO compliance)

################################################################################
# SOURCE MODULAR METRICS LIBRARIES
################################################################################

# Get the directory where this script is located
METRICS_LIB_DIR="${BASH_SOURCE[0]%/*}"
if [[ "$METRICS_LIB_DIR" != /* ]]; then
	METRICS_LIB_DIR="$(cd "$METRICS_LIB_DIR" 2>/dev/null && pwd)" || METRICS_LIB_DIR="."
fi

# Source all metrics sub-modules
[[ -f "$METRICS_LIB_DIR/metrics-system.sh" ]] && source "$METRICS_LIB_DIR/metrics-system.sh"
[[ -f "$METRICS_LIB_DIR/metrics-phase.sh" ]] && source "$METRICS_LIB_DIR/metrics-phase.sh"

export METRICS_LIB_DIR
export -f collect_system_metrics finalize_metrics display_metrics_summary
