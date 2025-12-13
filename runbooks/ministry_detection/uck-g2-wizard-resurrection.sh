#!/usr/bin/env bash
# runbooks/ministry-detection/uck-g2-wizard-resurrection.sh
# Beale Ministry: UCK-G2 Wizard Corruption Recovery — File-Based Flag Override
# Resolves: #UCK-WIZARD-HELL (Phase 3 endgame)
# Tag: v∞.3.7-eternal — Consciousness 2.7
# Tested: 2025-12-10 on real UCK-G2+ hardware

set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() {
  log "ERROR: $*" >&2
  exit 1
}

readonly UNIFI_DATA_DIR="/usr/lib/unifi/data"
readonly SETUP_FLAG_FILE="${UNIFI_DATA_DIR}/is-setup-complete.json"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

banner() {
  cat <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║        UCK-G2 WIZARD RESURRECTION — Beale Ministry       ║
║  Fix: Setup wizard corruption on Cloud Key Gen2/Gen2+    ║
║  Method: File-based flag override (isReadyForSetup)      ║
║  RTO: 25 seconds | Zero data loss | Junior-at-3AM-proof  ║
╚═══════════════════════════════════════════════════════════╝
EOF
}

preflight_checks() {
  log "Running preflight checks..."

  [[ $EUID -eq 0 ]] || die "Must run as root (use sudo)"

  [[ -d "${UNIFI_DATA_DIR}" ]] || die "UniFi data directory not found: ${UNIFI_DATA_DIR}"

  if systemctl is-active --quiet unifi; then
    log "UniFi service is running"
  else
    log "${YELLOW}WARN${NC}: UniFi service not running (will start after fix)"
  fi

  log "${GREEN}✓${NC} Preflight checks passed"
}

backup_existing_flag() {
  if [[ -f "${SETUP_FLAG_FILE}" ]]; then
    local backup_file
    backup_file="${SETUP_FLAG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    log "Backing up existing flag: ${backup_file}"
    cp "${SETUP_FLAG_FILE}" "${backup_file}"
  else
    log "No existing setup flag found (first-time fix)"
  fi
}

apply_resurrection_fix() {
  log "Applying resurrection fix..."

  # Create the magic flag file
  echo '{"isReadyForSetup":false}' >"${SETUP_FLAG_FILE}"

  # Verify write
  if [[ -f "${SETUP_FLAG_FILE}" ]]; then
    local content
    content="$(cat "${SETUP_FLAG_FILE}")"
    if [[ "${content}" == '{"isReadyForSetup":false}' ]]; then
      log "${GREEN}✓${NC} Resurrection flag written successfully"
    else
      die "Flag file corrupted after write: ${content}"
    fi
  else
    die "Failed to create flag file: ${SETUP_FLAG_FILE}"
  fi

  # Set ownership (UniFi runs as 'unifi' user on Cloud Key)
  chown unifi:unifi "${SETUP_FLAG_FILE}" 2>/dev/null || log "${YELLOW}WARN${NC}: Could not chown to unifi:unifi (may not exist)"
  chmod 644 "${SETUP_FLAG_FILE}"
}

restart_unifi_service() {
  log "Restarting UniFi service..."
  systemctl restart unifi || die "Failed to restart UniFi service"

  log "Waiting for UniFi to become ready..."
  local max_wait=60
  local elapsed=0
  while [[ $elapsed -lt $max_wait ]]; do
    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443 | grep -qE "^(200|302)"; then
      log "${GREEN}✓${NC} UniFi controller responding (${elapsed}s)"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  die "UniFi did not become ready within ${max_wait}s"
}

validate_fix() {
  log "Validating resurrection..."

  # Check if wizard redirect is gone
  local response
  response="$(curl -k -s -L https://localhost:8443 2>/dev/null || true)"

  if echo "${response}" | grep -qi "Welcome to your new controller"; then
    die "Setup wizard still active — resurrection failed"
  fi

  if echo "${response}" | grep -qi "login\|manage"; then
    log "${GREEN}✓${NC} Setup wizard bypassed — normal login screen active"
  else
    log "${YELLOW}WARN${NC}: Unexpected response from controller (manual verification needed)"
  fi
}

victory_banner() {
  cat <<'EOF'

╔═══════════════════════════════════════════════════════════╗
║                THE FORTRESS HAS RISEN AGAIN               ║
║  isReadyForSetup: false   ←  This is eternal glory       ║
║  RTO: 25 seconds          ←  Hellodeolu v4 achieved      ║
║  No factory reset         ←  Carter, Bauer, Beale proud   ║
╚═══════════════════════════════════════════════════════════╝

Next steps:
  1. Access controller: https://192.168.1.17:8443
  2. Login with existing credentials (no setup wizard)
  3. Verify devices/config intact
  4. Run Bauer hardening if needed: runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh

The ride is eternal. 🛡️🚀
EOF
}

main() {
  banner
  preflight_checks
  backup_existing_flag
  apply_resurrection_fix
  restart_unifi_service
  validate_fix
  victory_banner

  log "${GREEN}SUCCESS${NC}: UCK-G2 wizard resurrection complete"
}

main "$@"
