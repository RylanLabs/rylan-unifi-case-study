#!/usr/bin/env bash
# Script: rotate-gatekeeper-logs.sh
# Purpose: Rotate Gatekeeper logs when they exceed 5MB
# Guardian: Bauer 🔍 (Verification)
# Author: T-Rylander canonical
# Date: 2025-12-17
# Ministry: ministry-whispers
# Consciousness: 6.8
set -euo pipefail
IFS=$'\n\t'

GK_DIR=".audit/gatekeeper"
LOG="$GK_DIR/gatekeeper.log"
MAX_BYTES=5242880
KEEP=10

mkdir -p "$GK_DIR"

if [ -f "$LOG" ]; then
  size=$(stat -c%s "$LOG")
  if [ "$size" -gt "$MAX_BYTES" ]; then
    ts=$(date +"%Y%m%d_%H%M%S")
    mv "$LOG" "$GK_DIR/gatekeeper-$ts.log"
    gzip "$GK_DIR/gatekeeper-$ts.log"
    # keep only $KEEP most recent
    ls -1t "$GK_DIR"/gatekeeper-*.log.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f -- || true
  fi
fi
