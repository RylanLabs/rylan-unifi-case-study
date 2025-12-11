#!/bin/bash
# 05-network-migration/migrate.sh
# Purpose: Master migration orchestrator (Hellodeolu: <15 min RTO)
# Author: DT/Luke canonical
# Date: 2025-12-10
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME

echo "════════════════════════════════════════════════════════════"
echo "ETERNAL RESURRECTION: Network Migration Orchestrator"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════"
echo ""

# Phase 1: Pre-flight validation
echo "PHASE 1: Pre-flight validation"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/scripts/pre-flight.sh"; then
  echo "✅ Pre-flight passed"
else
  echo "❌ Pre-flight failed - aborting migration"
  exit 1
fi

echo ""
read -r -p "Continue with migration? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Migration aborted by user"
  exit 0
fi

# Phase 2: Push VLANs
echo ""
echo "PHASE 2: Pushing VLAN configuration"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/scripts/push-vlans.sh"; then
  echo "✅ VLANs configured"
else
  echo "❌ VLAN push failed"
  echo ""
  echo "Rollback available: $SCRIPT_DIR/rollback.sh"
  exit 1
fi

# Phase 3: Wait for network stabilization
echo ""
echo "PHASE 3: Waiting for network stabilization..."
echo "────────────────────────────────────────────────────────────"
echo "Waiting 60 seconds for devices to reconnect..."
sleep 60

# Phase 4: Post-flight validation
echo ""
echo "PHASE 4: Post-migration validation"
echo "────────────────────────────────────────────────────────────"
if "$SCRIPT_DIR/scripts/post-flight.sh"; then
  echo "✅ Post-flight passed"
else
  echo "⚠️  Post-flight warnings detected"
  echo "Review logs and verify manually"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ MIGRATION COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Verify devices in GUI: https://192.168.1.13"
echo "  2. Test inter-VLAN connectivity"
echo "  3. Push firewall rules: $SCRIPT_DIR/scripts/push-firewall.sh"
echo "  4. Update device inform URLs if controller IP changed"
echo ""
echo "Backup location: $SCRIPT_DIR/backups/"
echo "Rollback: $SCRIPT_DIR/rollback.sh"
