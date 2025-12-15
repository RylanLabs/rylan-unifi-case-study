#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/eternal-resurrect-unifi.sh
# Purpose: Orchestrator for UniFi controller resurrection (15-min RTO)
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# Eternal Resurrect – UniFi Controller (One-Command, Idempotent, 15-min RTO)
# USAGE: cd /opt/unifi && bash /path/to/eternal-resurrect-unifi.sh

# shellcheck disable=SC2034  # color constants used for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# shellcheck disable=SC2317
log_info() { echo -e "${BLUE}[RESURRECT]${NC} $1"; }
log_success() { echo -e "${GREEN}[RESURRECT]${NC} ✅ $1"; }
log_error() {
  echo -e "${RED}[RESURRECT]${NC} ❌ $1"
  exit 1
}
log_warn() { echo -e "${YELLOW}[RESURRECT]${NC} ⚠️  $1"; }

cat <<'BANNER'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║         🔥 ETERNAL RESURRECT – UniFi Controller Resurrection 🔥           ║
║                                                                            ║
║               One-Command Recovery · 15-min RTO · Dec 2025                ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

BANNER

CONTROLLER_IP="10.0.1.20"
CONTROLLER_PORT="8443"
# shellcheck disable=SC2034  # variables consumed by sourced modules
DATA_DIR="/opt/unifi/data"
# shellcheck disable=SC2034  # variables consumed by sourced modules
WORK_DIR="/opt/unifi"
# shellcheck disable=SC2034  # variables consumed by sourced modules
MAX_RETRIES=30
# shellcheck disable=SC2034  # variables consumed by sourced modules
RETRY_DELAY=2

# ============================================================================
# SOURCE MODULES
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/resurrect-preflight.sh
source "${SCRIPT_DIR}/lib/resurrect-preflight.sh"
# shellcheck source=./lib/resurrect-container.sh
source "${SCRIPT_DIR}/lib/resurrect-container.sh"

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

run_preflight_validation
run_network_validation
run_container_resurrection
run_health_verification
run_final_verification

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    🔥 RESURRECTION COMPLETE 🔥${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Controller IP:     $CONTROLLER_IP"
echo "  Port:              $CONTROLLER_PORT"
echo "  Web UI:            https://$CONTROLLER_IP:8443"
echo "  Container Name:    unifi-controller"
echo "  Status:            Running"
echo ""
echo "  Next Steps:"
echo "    1. Wait 30-60 seconds for full initialization"
echo "    2. Open https://$CONTROLLER_IP:8443 in browser"
echo "    3. Accept self-signed certificate"
echo "    4. Log in (ubnt/ubnt → change immediately)"
echo ""
echo "  Monitoring:"
echo "    docker logs -f unifi-controller      (live logs)"
echo "    docker ps | grep unifi               (container status)"
echo "    curl -k https://$CONTROLLER_IP:8443/status  (health)"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
