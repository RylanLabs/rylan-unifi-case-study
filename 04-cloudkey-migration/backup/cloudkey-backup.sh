#!/usr/bin/env bash
# Cloud Key Daily Backup — Cron Job for Eternal Resilience
# Scheduled: 0 3 * * * /usr/local/bin/cloudkey-backup.sh

set -euo pipefail

# Configuration
CLOUDKEY_IP="${CLOUDKEY_IP:---10.0.1.30}"
BACKUP_DIR="/var/backups/cloudkey"
BACKUP_USER="ubnt"
LOG_FILE="/var/log/cloudkey-backup.log"
RETENTION_DAYS="30"

# Logging
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" | tee -a "$LOG_FILE"; }
log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE"; }

# Create backup directory
mkdir -p "$BACKUP_DIR"

log_info "Starting Cloud Key backup (Controller: $CLOUDKEY_IP)"

# Test SSH access
if ! timeout 5 ssh -o ConnectTimeout=5 "$BACKUP_USER@$CLOUDKEY_IP" "echo 'OK'" >/dev/null 2>&1; then
  log_error "Cannot SSH to Cloud Key at $CLOUDKEY_IP"
  exit 1
fi

log_success "SSH access confirmed"

# Trigger backup on Cloud Key
log_info "Triggering backup on Cloud Key..."
if ! ssh "$BACKUP_USER@$CLOUDKEY_IP" >/tmp/cloudkey-backup.tmp 2>&1 <<'BACKUP_CMD'; then
  unifi-os backup
BACKUP_CMD
  log_error "Backup trigger failed"
  exit 1
fi

# Extract backup file path from output
BACKUP_FILE=$(grep -oP '(?<=/data/autobackup/)[^ ]+' /tmp/cloudkey-backup.tmp | head -1 || echo "")

if [ -z "$BACKUP_FILE" ]; then
  log_warn "Could not detect backup file; attempting standard path"
  BACKUP_FILE="unifi-backup-$(date +%s).unf"
fi

log_info "Backup file: $BACKUP_FILE"

# Download backup
log_info "Downloading backup..."
scp "$BACKUP_USER@$CLOUDKEY_IP:/data/autobackup/$BACKUP_FILE" \
  "$BACKUP_DIR/cloudkey-$(date +%Y%m%d-%H%M%S).unf" || {
  log_error "SCP failed"
  exit 1
}

log_success "Backup downloaded"

# Compress and encrypt (optional but recommended)
# gpg -c --cipher-algo AES256 "$BACKUP_DIR/cloudkey-*.unf"
# rm "$BACKUP_DIR/cloudkey-*.unf"

# Cleanup old backups
log_info "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "cloudkey-*.unf*" -mtime "+$RETENTION_DAYS" -delete

log_success "Backup complete"

# Notify on failure (optional; requires osTicket webhook)
# if [ $? -ne 0 ]; then
#   curl -X POST http://osticket.internal/api/webhook \
#     -d '{"subject":"Cloud Key Backup Failed","message":"Check $LOG_FILE"}' 2>/dev/null || true
# fi

exit 0
