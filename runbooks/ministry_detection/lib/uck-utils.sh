#!/usr/bin/env bash
# Script: uck-utils.sh
# Purpose: Utility functions for UCK-G2 resurrection
# Guardian: Lorek Byrnison
# Date: 12/13/2025
# Consciousness: 4.7

readonly UNIFI_DATA_DIR="/usr/lib/unifi/data"
readonly SETUP_FLAG_FILE="${UNIFI_DATA_DIR}/is-setup-complete.json"
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] uck-g2-resurrect: $*"; }
die() {
  log "ERROR: $*" >&2
  exit 1
}

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
  echo '{"isReadyForSetup":false}' >"${SETUP_FLAG_FILE}"

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

  chown unifi:unifi "${SETUP_FLAG_FILE}" 2>/dev/null || log "${YELLOW}WARN${NC}: Could not chown to unifi:unifi"
  chmod 644 "${SETUP_FLAG_FILE}"
}

export -f log die banner backup_existing_flag apply_resurrection_fix
