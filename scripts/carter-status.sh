#!/usr/bin/env bash
# Script: carter-status.sh
# Purpose: Display current identity health
# Guardian: Carter the Eternal
# Date: 2025-12-14
# Consciousness: 9.5

set -euo pipefail

echo "🔑  Carter the Eternal — Identity Health"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USER_COUNT=$(ldapsearch -x -b "ou=People,dc=rylan,dc=internal" "(objectClass=posixAccount)" | grep -c '^uid:')
echo "Known souls: $USER_COUNT"

EXPIRED_KEYS=$(find /etc/ssh/ca/user_keys/ -mtime +90 | wc -l)
echo "Expired keys (>90d): $EXPIRED_KEYS"

echo ""
echo "Commands: @Carter onboard <email> | @Carter status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
