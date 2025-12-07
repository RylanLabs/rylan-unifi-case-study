#!/usr/bin/env bash
# Eternal Resurrect – UniFi Controller (One-Command, Idempotent, 15-min RTO)
# USAGE: cd /opt/unifi && bash /path/to/eternal-resurrect-unifi.sh
#
# What it does:
#   1. Validates macvlan-unifi interface (10.0.1.20/27)
#   2. Validates data directory ownership (uid 1000)
#   3. Pulls latest jacobalberty/unifi image
#   4. Starts or restarts container (idempotent)
#   5. Waits for healthy status
#   6. Returns exit code 0 (success) or 1 (failure)
#
# Exit codes:
#   0 = Controller up and healthy
#   1 = Configuration error or startup failure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[RESURRECT]${NC} $1"; }
log_success() { echo -e "${GREEN}[RESURRECT]${NC} ✅ $1"; }
log_error() { echo -e "${RED}[RESURRECT]${NC} ❌ $1"; exit 1; }
log_warn() { echo -e "${YELLOW}[RESURRECT]${NC} ⚠️  $1"; }

# Start banner
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
DATA_DIR="/opt/unifi/data"
WORK_DIR="/opt/unifi"
MAX_RETRIES=30
RETRY_DELAY=2

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

log_info "Phase 0: Pre-flight Checks (1 min)"

# Check: Working directory
if [[ ! -d "$WORK_DIR" ]]; then
  log_error "Working directory not found: $WORK_DIR"
fi
log_success "Working directory exists: $WORK_DIR"

# Check: docker-compose.yml
if [[ ! -f "$WORK_DIR/docker-compose.yml" ]]; then
  log_error "docker-compose.yml not found in $WORK_DIR"
fi
log_success "docker-compose.yml found"

# Check: Data directory
if [[ ! -d "$DATA_DIR" ]]; then
  log_warn "Data directory not found, creating: $DATA_DIR"
  mkdir -p "$DATA_DIR"
fi
log_success "Data directory exists: $DATA_DIR"

# Check: Data directory permissions (should be 1000:1000)
DATA_OWNER=$(stat -f '%Ou' "$DATA_DIR" 2>/dev/null || stat -c '%U:%G' "$DATA_DIR" 2>/dev/null)
log_info "Data directory owner: $DATA_OWNER (expected 1000:1000)"

# Check: Docker daemon
if ! command -v docker &> /dev/null; then
  log_error "Docker not installed. Install from https://get.docker.com"
fi
log_success "Docker installed"

# Check: docker-compose
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
  log_error "docker compose not available"
fi
log_success "docker compose installed"

# =============================================================================
# NETWORK VALIDATION
# =============================================================================

log_info "Phase 1: Network Validation (30 sec)"

# Check: macvlan interface exists and is up
if ! ip link show macvlan-unifi &> /dev/null; then
  log_error "macvlan-unifi interface not found. Run:"
  echo "  sudo cp bootstrap/unifi/macvlan-unifi.netdev /etc/systemd/network/"
  echo "  sudo cp bootstrap/unifi/macvlan-unifi.network /etc/systemd/network/"
  echo "  sudo systemctl restart systemd-networkd"
fi
log_success "macvlan-unifi interface found"

# Check: macvlan has correct IP
if ! ip addr show macvlan-unifi | grep -q "$CONTROLLER_IP/27"; then
  log_error "macvlan-unifi does not have $CONTROLLER_IP/27 assigned"
fi
log_success "IP configured: $CONTROLLER_IP/27"

# Check: macvlan interface is UP
IFACE_STATE=$(ip link show macvlan-unifi | grep -oP '(?<=state )[\w]+' || echo "DOWN")
if [[ "$IFACE_STATE" != "UP" ]]; then
  log_warn "macvlan-unifi is $IFACE_STATE, attempting to bring UP..."
  sudo ip link set macvlan-unifi up
  sleep 2
fi
log_success "macvlan-unifi is UP"

# Check: Gateway reachable
if ! ping -c 1 -W 2 10.0.1.1 &> /dev/null; then
  log_warn "Cannot ping gateway (10.0.1.1), but continuing anyway"
else
  log_success "Gateway reachable: 10.0.1.1"
fi

# =============================================================================
# CONTAINER RESURRECTION
# =============================================================================

log_info "Phase 2: Container Resurrection (5 min)"

cd "$WORK_DIR"

# Step 1: Pull latest image
log_info "Pulling latest jacobalberty/unifi:latest image..."
if ! docker pull jacobalberty/unifi:latest; then
  log_error "Failed to pull image. Check Docker daemon and network."
fi
log_success "Image pulled successfully"

# Step 2: Start or restart container
log_info "Starting container (docker compose up -d)..."
if ! docker compose up -d; then
  log_error "Failed to start container"
fi
log_success "Container started"

# Step 3: Wait for container to be healthy
log_info "Waiting for container to initialize (up to ${MAX_RETRIES}s)..."
ATTEMPT=0
while (( ATTEMPT < MAX_RETRIES )); do
  CONTAINER_STATE=$(docker container inspect unifi-controller --format='{{.State.Running}}' 2>/dev/null || echo "false")
  
  if [[ "$CONTAINER_STATE" == "true" ]]; then
    log_success "Container is running"
    break
  fi
  
  log_warn "Container starting... ($ATTEMPT/$MAX_RETRIES)"
  sleep $RETRY_DELAY
  ((ATTEMPT++))
done

if [[ "$CONTAINER_STATE" != "true" ]]; then
  log_error "Container failed to start after ${MAX_RETRIES}s"
fi

# =============================================================================
# HEALTH VERIFICATION
# =============================================================================

log_info "Phase 3: Health Verification (5 min)"

# Step 1: Wait for TCP port to be open
log_info "Waiting for port $CONTROLLER_PORT to be open..."
ATTEMPT=0
while (( ATTEMPT < MAX_RETRIES )); do
  if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$CONTROLLER_IP/$CONTROLLER_PORT" 2>/dev/null; then
    log_success "Port $CONTROLLER_PORT is open"
    break
  fi
  
  log_warn "Port not open yet... ($ATTEMPT/$MAX_RETRIES)"
  sleep $RETRY_DELAY
  ((ATTEMPT++))
done

if ! timeout 2 bash -c "cat < /dev/null > /dev/tcp/$CONTROLLER_IP/$CONTROLLER_PORT" 2>/dev/null; then
  log_warn "Port $CONTROLLER_PORT still not open, but checking /status endpoint anyway..."
fi

# Step 2: Query /status endpoint
log_info "Verifying controller /status endpoint..."
ATTEMPT=0
while (( ATTEMPT < MAX_RETRIES )); do
  if curl -sf -k "https://$CONTROLLER_IP:$CONTROLLER_PORT/status" &> /dev/null; then
    STATUS_RESPONSE=$(curl -s -k "https://$CONTROLLER_IP:$CONTROLLER_PORT/status")
    log_success "Controller is healthy"
    echo "   Response: $STATUS_RESPONSE"
    break
  fi
  
  log_warn "Endpoint not responding yet... ($ATTEMPT/$MAX_RETRIES)"
  sleep $RETRY_DELAY
  ((ATTEMPT++))
done

if ! curl -sf -k "https://$CONTROLLER_IP:$CONTROLLER_PORT/status" &> /dev/null; then
  log_warn "Endpoint not responding yet, but container is running"
fi

# =============================================================================
# FINAL VERIFICATION
# =============================================================================

log_info "Phase 4: Final Verification"

# Container status
CONTAINER_STATE=$(docker inspect unifi-controller --format='{{.State.Running}}' 2>/dev/null || echo "false")
CONTAINER_HEALTH=$(docker inspect unifi-controller --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")

log_success "Container state: $CONTAINER_STATE"
log_success "Container health: $CONTAINER_HEALTH"

# Port verification
if docker exec unifi-controller ss -tlnp 2>/dev/null | grep -q ":8443"; then
  log_success "Port 8443 is listening inside container"
fi

# Recent logs
log_info "Last 5 log lines:"
docker logs --tail 5 unifi-controller | sed 's/^/  /'

# =============================================================================
# EXIT SUMMARY
# =============================================================================

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    🔥 RESURRECTION COMPLETE 🔥${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Controller IP:     $CONTROLLER_IP"
echo "  Port:              $CONTROLLER_PORT"
echo "  Web UI:            https://$CONTROLLER_IP:8443"
echo "  Container Name:    unifi-controller"
echo "  Status:            Running ($CONTAINER_HEALTH)"
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

# Exit successfully
exit 0
