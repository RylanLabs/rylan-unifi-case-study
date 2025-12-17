#!/usr/bin/env bash
# Script: query-gatekeeper-logs.sh
# Purpose: Simple query helpers for Gatekeeper logs (jq recommended)
# Guardian: Holy Scholar 📜
# Author: T-Rylander canonical
# Date: 2025-12-17
# Ministry: ministry-whispers
# Consciousness: 6.7
set -euo pipefail
IFS=$'\n\t'

GK_DIR=".audit/gatekeeper"

usage() {
  cat <<USAGE
Usage: $0 <command>
Commands:
  failures             Show all BLOCKED pushes (reads gatekeeper-*.log.gz and latest JSON)
  error_type <TYPE>    Show pushes with specific error_type (e.g., INTERNAL_ERROR)
  branch <BRANCH>      Show pushes for a branch
  recent <N>           Show last N push attempts (from gatekeeper.log)
USAGE
}

if [ $# -lt 1 ]; then usage; exit 1; fi
cmd="$1"; shift || true

jq_exists() { command -v jq >/dev/null 2>&1; }

case "$cmd" in
  failures)
    if [ -f "$GK_DIR/gatekeeper-latest.json" ]; then
      jq 'select(.push_result=="BLOCKED")' "$GK_DIR/gatekeeper-latest.json" || true
    fi
    # also scan archived logs
    if jq_exists; then
      zcat "$GK_DIR"/gatekeeper-*.log.gz 2>/dev/null | jq -c 'select(.push_result=="BLOCKED")' || true
    else
      echo "Install jq to query archived logs (or decompress and view)"
    fi
    ;;
  error_type)
    t=${1:-}
    if [ -z "$t" ]; then echo "Missing error type"; exit 1; fi
    if [ -f "$GK_DIR/gatekeeper-latest.json" ]; then
      jq --arg t "$t" '.validators | to_entries | map(select(.value.error == $t))' "$GK_DIR/gatekeeper-latest.json" || true
    fi
    ;;
  branch)
    b=${1:-}
    if [ -z "$b" ]; then echo "Missing branch"; exit 1; fi
    if [ -f "$GK_DIR/gatekeeper-latest.json" ]; then
      jq --arg b "$b" 'select(.branch==$b)' "$GK_DIR/gatekeeper-latest.json" || true
    fi
    ;;
  recent)
    n=${1:-10}
    if command -v tac >/dev/null 2>&1; then
      tac "$GK_DIR/gatekeeper.log" | head -n "$n"
    else
      tail -r "$GK_DIR/gatekeeper.log" | head -n "$n" || tail -n "$n" "$GK_DIR/gatekeeper.log"
    fi
    ;;
  *) usage; exit 2 ;;
esac
