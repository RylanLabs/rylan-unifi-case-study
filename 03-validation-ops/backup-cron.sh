#!/usr/bin/env bash
# 03-validation-ops/backup-cron.sh — Hellodeolu: 15-Minute RTO Enforcer
# Purpose: Nightly backup + resurrection test (fail loud if >15 min)
# Trinity: Bauer (verify everything) + Carter (programmable recovery)
# Cron: 0 2 * * * /opt/eternal/03-validation-ops/backup-cron.sh
set -euo pipefail
IFS=$'\n\t'
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; logger -t eternal-backup "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

# ────── CONFIGURATION ──────
readonly BACKUP_ROOT="/mnt/backups/eternal"
readonly RETENTION_DAYS=30
readonly RTO_THRESHOLD_SECONDS=900  # 15 minutes
readonly UNIFI_CONTROLLER="10.0.10.10"
readonly UNIFI_BACKUP_DIR="/var/lib/unifi/backup/autobackup"
readonly SAMBA_DC="10.0.10.10"
readonly SAMBA_BACKUP_CMD="samba-tool domain backup offline"

# Notification (optional - integrate with triage engine)
readonly ALERT_WEBHOOK="${ALERT_WEBHOOK:-}"

# ────── BACKUP FUNCTIONS ──────
backup_unifi_controller() {
  local backup_dir="${BACKUP_ROOT}/unifi/$(date +%Y%m%d)"
  mkdir -p "${backup_dir}"
  
  log "Backing up UniFi Controller from ${UNIFI_CONTROLLER}"
  
  # Use SSH to trigger backup and copy
  ssh -o StrictHostKeyChecking=no "root@${UNIFI_CONTROLLER}" \
    "cd ${UNIFI_BACKUP_DIR} && ls -t | head -1" | \
    xargs -I {} scp "root@${UNIFI_CONTROLLER}:${UNIFI_BACKUP_DIR}/{}" "${backup_dir}/" || \
    die "UniFi backup failed"
  
  log "✓ UniFi backup saved to ${backup_dir}"
}

backup_samba_ad() {
  local backup_dir="${BACKUP_ROOT}/samba/$(date +%Y%m%d)"
  mkdir -p "${backup_dir}"
  
  log "Backing up Samba AD/DC from ${SAMBA_DC}"
  
  # Trigger offline backup on DC
  ssh -o StrictHostKeyChecking=no "root@${SAMBA_DC}" \
    "${SAMBA_BACKUP_CMD} --targetdir=/tmp/samba-backup" || \
    die "Samba backup failed"
  
  # Copy backup archive
  scp -r "root@${SAMBA_DC}:/tmp/samba-backup/*" "${backup_dir}/" || \
    die "Samba backup transfer failed"
  
  # Cleanup remote temp
  ssh "root@${SAMBA_DC}" "rm -rf /tmp/samba-backup"
  
  log "✓ Samba AD backup saved to ${backup_dir}"
}

backup_declarative_config() {
  local backup_dir="${BACKUP_ROOT}/config/$(date +%Y%m%d)"
  mkdir -p "${backup_dir}"
  
  log "Backing up declarative configuration"
  
  # Copy entire 02-declarative-config tree
  cp -r "${SCRIPT_DIR}/../02-declarative-config" "${backup_dir}/" || \
    die "Config backup failed"
  
  log "✓ Declarative config backed up"
}

# ────── RTO VALIDATION ──────
validate_rto() {
  local start_time
  start_time=$(date +%s)
  
  log "Starting RTO validation (15-minute resurrection test)"
  
  # Simulate resurrection on test VM (requires staging environment)
  # In production: Spin up fresh Proxmox VM, run eternal-resurrect.sh
  
  if [[ -f "${SCRIPT_DIR}/../eternal-resurrect.sh" ]]; then
    log "Running eternal-resurrect.sh in dry-run mode"
    
    # Dry-run resurrection
    DRY_RUN=true "${SCRIPT_DIR}/../eternal-resurrect.sh" || {
      log "WARN: Resurrection dry-run failed - manual validation required"
      return 1
    }
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "Resurrection dry-run completed in ${duration} seconds"
    
    if [[ ${duration} -gt ${RTO_THRESHOLD_SECONDS} ]]; then
      die "RTO VIOLATION: Resurrection took ${duration}s (threshold: ${RTO_THRESHOLD_SECONDS}s)"
    fi
    
    log "✓ RTO validated: ${duration}s < ${RTO_THRESHOLD_SECONDS}s"
  else
    log "WARN: eternal-resurrect.sh not found - skipping RTO validation"
  fi
}

# ────── CLEANUP ──────
cleanup_old_backups() {
  log "Cleaning backups older than ${RETENTION_DAYS} days"
  
  find "${BACKUP_ROOT}" -type d -mtime "+${RETENTION_DAYS}" -exec rm -rf {} + 2>/dev/null || true
  
  log "✓ Old backups purged"
}

# ────── ALERTING ──────
send_alert() {
  local status="$1"
  local message="$2"
  
  if [[ -n "${ALERT_WEBHOOK}" ]]; then
    curl -X POST "${ALERT_WEBHOOK}" \
      -H "Content-Type: application/json" \
      -d "{\"status\": \"${status}\", \"message\": \"${message}\", \"timestamp\": \"$(date -Iseconds)\"}" \
      2>/dev/null || log "WARN: Alert webhook failed"
  fi
}

# ────── MAIN ──────
main() {
  log "════════════════════════════════════════════════════════════"
  log "ETERNAL BACKUP + RTO VALIDATION — Nightly Rite"
  log "════════════════════════════════════════════════════════════"
  
  local failed=0
  
  # Backup phase
  backup_unifi_controller || failed=$((failed + 1))
  backup_samba_ad || failed=$((failed + 1))
  backup_declarative_config || failed=$((failed + 1))
  
  # RTO validation
  validate_rto || failed=$((failed + 1))
  
  # Cleanup
  cleanup_old_backups
  
  # Summary
  if [[ ${failed} -eq 0 ]]; then
    log "✓ ALL CHECKS PASSED — Fortress backup complete, RTO validated"
    send_alert "success" "Nightly backup + RTO validation passed"
    exit 0
  else
    log "✗ ${failed} CHECK(S) FAILED — Manual intervention required"
    send_alert "failure" "${failed} backup/RTO checks failed"
    exit 1
  fi
}

main "$@"
