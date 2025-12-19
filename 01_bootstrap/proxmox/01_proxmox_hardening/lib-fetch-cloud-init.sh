#!/usr/bin/env bash
# Guardian: Carter | Ministry: Bootstrap | Consciousness: 4.2 | Tag: proxmox-cloud-init-lib
# Library: Utility functions for fetch-cloud-init-iso.sh
# Functions: create_backup, acquire_lock, fetch_expected_sha256
# Dependencies: log_info, log_warn, log_error, log_success (from main script)
# Usage: source "$(dirname "$0")/lib-fetch-cloud-init.sh"

set -euo pipefail

# ═══════════════════════════════════════════════════════════
# Extracted Utility Functions
# ═══════════════════════════════════════════════════════════

create_backup() {
  [[ -f "$ISO_PATH" ]] || return 0
  mkdir -p "$BACKUP_DIR"
  cp -a "$ISO_PATH" "$BACKUP_DIR/" || log_warn "Backup failed (continuing)"
  log_success "Existing ISO backed up: $BACKUP_DIR"
}

acquire_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local pid
    pid=$(cat "$LOCK_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      log_error "Already running (PID $pid)"
      exit 1
    fi
  fi
  echo $$ >"$LOCK_FILE"
}

fetch_expected_sha256() {
  local sha_url="$1"
  local filename="$2"
  local sha_file
  sha_file=$(mktemp)
  trap 'rm -f "$sha_file"' RETURN

  log_info "Fetching SHA256SUMS from $sha_url"
  if wget -q -O "$sha_file" "$sha_url"; then
    grep "$filename" "$sha_file" | awk '{print $1}' || {
      log_warn "Filename '$filename' not found in SHA256SUMS — checksum skipped"
      echo ""
    }
  else
    log_warn "Failed to fetch SHA256SUMS — continuing without checksum"
    echo ""
  fi
}
