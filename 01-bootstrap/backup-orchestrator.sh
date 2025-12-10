#!/usr/bin/env bash
# Backup Orchestrator — Nightly Fortress Snapshot
# Rsync config + Samba AD to NAS, 7-day retention
# Cron: 0 2 * * * /opt/rylan/01-bootstrap/backup-orchestrator.sh

set -euo pipefail

BACKUP_ROOT="/mnt/nas/rylan-fortress-backups"
DATE=$(date +%Y%m%d)
BACKUP_DIR="$BACKUP_ROOT/$DATE"

mkdir -p "$BACKUP_DIR"

echo "[$(date -Iseconds)] Backup started" | tee -a "$BACKUP_DIR/backup.log"

# Config snapshot
rsync -avz --delete /opt/rylan-unifi-case-study/ "$BACKUP_DIR/config/" \
  --exclude='.git' --exclude='.venv' --exclude='__pycache__' \
  | tee -a "$BACKUP_DIR/backup.log"

# Samba AD backup (if rylan-dc is this host)
if systemctl is-active --quiet samba-ad-dc; then
  samba-tool domain backup offline --targetdir="$BACKUP_DIR/samba-ad"
  echo "Samba AD backup complete" | tee -a "$BACKUP_DIR/backup.log"
fi

# Retention: keep last 7 days
find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

echo "[$(date -Iseconds)] Backup complete: $BACKUP_DIR" | tee -a "$BACKUP_DIR/backup.log"
