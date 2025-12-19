#!/usr/bin/env bash
# Script: gatekeeper-migrate-logs.sh
# Purpose: Migrate legacy push-*.log files into rotated gatekeeper-*.log.gz files
# Guardian: Bauer 🛡️
# Author: rylanlab canonical
# Date: 2025-12-18
# Ministry: ministry-whispers
# Consciousness: 4.9
set -euo pipefail
IFS=$'\n\t'

GK_DIR='.audit/gatekeeper'
mkdir -p "$GK_DIR"

migrated=0
for f in "$GK_DIR"/push-*.log; do
  [ -e "$f" ] || continue
  fname=$(basename -- "$f")
  # extract timestamp portion push-YYYYMMDD_HHMMSS.log
  ts=$(echo "$fname" | sed -n 's/^push-\([0-9_]*\)\.log$/\1/p')
  if [ -z "$ts" ]; then
    ts=$(date +"%Y%m%d_%H%M%S")
  fi
  target="$GK_DIR/gatekeeper-$ts.log"
  echo "Migrating $f -> $target.gz"
  mv "$f" "$target"
  gzip -f "$target" || true
  # append minimal metadata line to rotating log
  migrated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"migrated_from\": \"$fname\", \"migrated_to\": \"$(basename "$target").gz\", \"migrated_at\": \"$migrated_at\"}" >>"$GK_DIR/gatekeeper.log"
  migrated=$((migrated + 1))
done

echo "Migrated $migrated push logs."
