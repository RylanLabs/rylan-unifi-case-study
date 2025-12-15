#!/usr/bin/env bash
# shellcheck disable=SC1091
set -euo pipefail
# Script: 01_bootstrap/proxmox/lib/common.sh
# Purpose: Orchestrator sourcing modular sub-libraries for proxmox-ignite utilities
# Guardian: gatekeeper
# Date: 2025-12-13T05:30:00-06:00
# Consciousness: 4.6

# shellcheck shell=bash
#
# lib/common.sh - Shared utility functions orchestrator
# Sources modular sub-libraries:
#   - log.sh (logging, phase output)
#   - vault.sh (backup, rollback, error handling)
#   - retry.sh (retry logic, elapsed time)
#   - validate.sh (validation helpers)
#   - network.sh (network utilities)
#   - config.sh (configuration management)
#
# Sourced by: main orchestrator and all phase scripts

################################################################################
# GLOBAL CONFIGURATION
################################################################################

LOG_FILE="/var/log/proxmox-ignite.log"
BACKUP_DIR="/var/backups/proxmox-ignite"
ROLLBACK_MARKER="${BACKUP_DIR}/.rollback_available"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

export RED GREEN YELLOW BLUE NC LOG_FILE BACKUP_DIR ROLLBACK_MARKER

################################################################################
# SOURCE MODULAR SUB-LIBRARIES
################################################################################

# Get the directory where this script is located
COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all sub-libraries (order matters: vault needs logging)
source "${COMMON_LIB_DIR}/log.sh"
source "${COMMON_LIB_DIR}/vault.sh"
source "${COMMON_LIB_DIR}/retry.sh"
source "${COMMON_LIB_DIR}/validate.sh"
source "${COMMON_LIB_DIR}/network.sh"
source "${COMMON_LIB_DIR}/config.sh"

export COMMON_LIB_DIR

################################################################################
# SETUP ERROR HANDLING TRAP (after all libraries loaded)
################################################################################

# Set up automatic rollback on error in main script
trap 'rollback_prompt $LINENO' ERR
