#!/usr/bin/env bash
# UniFi + Helpdesk backup cron helper.
# Example usage (cron): 0 3 * * * /path/backup-cron.sh >> /var/log/backup.log 2>&1

set -euo pipefail
STAMP=$(date +%Y%m%d-%H%M%S)
DEST=${BACKUP_DEST:-/var/backups/rylan}
mkdir -p "$DEST"

echo "[backup] Starting backup at $STAMP"

# UniFi config backup (expects unifi-data volume mounted)
if [ -d /var/lib/unifi ]; then
  tar -czf "$DEST/unifi-$STAMP.tgz" /var/lib/unifi/data --exclude='*.log'
  echo "✅ UniFi config archived"
else
  echo "⚠️ /var/lib/unifi not found, skipping controller backup"
fi

# Helpdesk (tickets DB) placeholder - adapt to actual DB dump command
if command -v pg_dump >/dev/null 2>&1; then
  pg_dump "$HELPDESK_DB_URL" > "$DEST/helpdesk-$STAMP.sql" || echo "⚠️ helpdesk DB dump failed"
fi

echo "[backup] Completed"
