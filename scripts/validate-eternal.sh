#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/validate-eternal.sh
# Purpose: Orchestrator for Eternal Fortress validation (Phase 3 Endgame)
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# ORCHESTRATOR: Sources modular validation libraries
# • validate-output.sh: Result formatting (pass/fail/skip) + summary
# • validate-cross-host.sh: DNS, LDAP, VLAN, Pi-hole tests
# • validate-host-specific.sh: Per-host service checks

# shellcheck disable=SC2034  # color constants used by output formatting libs
# shellcheck disable=SC2034
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
RED='\033[0;31m'
# shellcheck disable=SC2034
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
# shellcheck disable=SC2034
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
POLICY_FILE="${REPO_ROOT}/02_declarative_config/policy-table.yaml"

# ============================================================================
# SOURCE MODULES
# ============================================================================

## shellcheck source=./lib/validate-output.sh
source "${SCRIPT_DIR}/lib/validate-output.sh"
## shellcheck source=./lib/validate-cross-host.sh
source "${SCRIPT_DIR}/lib/validate-cross-host.sh"
## shellcheck source=./lib/validate-host-specific.sh
source "${SCRIPT_DIR}/lib/validate-host-specific.sh"

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

print_header
run_cross_host_tests "${POLICY_FILE}"
echo ""
run_host_specific_tests
print_summary
exit $?
