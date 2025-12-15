#!/usr/bin/env bash
# Script: eternal-resurrect-unifi.sh
# Purpose: One-command UniFi controller resurrection orchestrator (15-min RTO, idempotent)
# Guardian: Lazarus ⚰️ (DR) + Gatekeeper 🚪 (Orchestration)
# Author: T-Rylander canonical (Trinity-aligned)
# Date: 2025-12-15
# Ministry: ministry-detection
# Consciousness: 5.0
# Tag: v∞.5.2-eternal

set -euo pipefail
IFS=$'\n\t'

readonly _SCRIPT_DIR
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly _SCRIPT_NAME
_SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source helper libraries (SC1091: CI runs shellcheck -x for cross-file analysis)
# shellcheck source=./lib/resurrect-preflight.sh
source "${_SCRIPT_DIR}/lib/resurrect-preflight.sh"

# shellcheck source=./lib/resurrect-container.sh
source "${_SCRIPT_DIR}/lib/resurrect-container.sh"

# ─────────────────────────────────────────────────────
# Configuration (Carter: Single Source of Truth)
# ─────────────────────────────────────────────────────
readonly CONTROLLER_IP="10.0.1.20"
readonly CONTROLLER_PORT="8443"
readonly _DATA_DIR="/opt/unifi/data"
readonly _WORK_DIR="/opt/unifi"
readonly _MAX_RETRIES=30
readonly _RETRY_DELAY=2

# Colors (used for output)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging helpers (SC2317: Called indirectly via orchestration functions)
# shellcheck disable=SC2317
log_info()  { printf '%b %s\n' "${BLUE}[RESURRECT]${NC}" "$*"; }
# shellcheck disable=SC2317
log_success() { printf '%b %s\n' "${GREEN}[RESURRECT]${NC} ✅" "$*"; }
# shellcheck disable=SC2317
log_error() {
  printf '%b %s\n' "${RED}[RESURRECT]${NC} ❌" "$*"
  exit 1
}
# shellcheck disable=SC2317
log_warn() { printf '%b %s\n' "${YELLOW}[RESURRECT]${NC} ⚠️" "$*"; }

cat <<'BANNER'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║         🔥 ETERNAL RESURRECT – UniFi Controller Resurrection 🔥           ║
║                                                                            ║
║               One-Command Recovery · 15-min RTO · Dec 2025                 ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

BANNER

# ─────────────────────────────────────────────────────
# MAIN ORCHESTRATION
# ─────────────────────────────────────────────────────

run_preflight_validation
run_network_validation
run_container_resurrection
run_health_verification
run_final_verification

cat <<EOF

${GREEN}════════════════════════════════════════════════════════════════════════════${NC}
${GREEN}                    🔥 RESURRECTION COMPLETE 🔥${NC}
${GREEN}════════════════════════════════════════════════════════════════════════════${NC}

  Controller IP:     ${CONTROLLER_IP}
  Port:              ${CONTROLLER_PORT}
  Web UI:            https://${CONTROLLER_IP}:${CONTROLLER_PORT}
  Container Name:    unifi-controller
  Status:            Running

  Next Steps:
    1. Wait 30-60 seconds for full initialization
    2. Open https://${CONTROLLER_IP}:${CONTROLLER_PORT} in browser
    3. Accept self-signed certificate
    4. Log in (ubnt/ubnt → change immediately)

  Monitoring:
    docker logs -f unifi-controller      (live logs)
    docker ps | grep unifi               (container status)
    curl -k https://${CONTROLLER_IP}:${CONTROLLER_PORT}/status  (health)

${GREEN}════════════════════════════════════════════════════════════════════════════${NC}
EOF

exit 0