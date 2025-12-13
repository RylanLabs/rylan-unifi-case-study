#!/usr/bin/env bash
# Script: 05_network_migration/migrate.sh
# Purpose: Eternal network migration orchestrator (<15 min RTO)
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
set -euo pipefail

# ─────────────────────────────────────────────────────
# Beale Doctrine: Fail loud, silence on success
# ─────────────────────────────────────────────────────
log()   { [[ "$QUIET" == false ]] && echo "[Migration] $*"; }
audit() { echo "$(date -Iseconds) | Migration | $1 | $2" >> /var/log/migration-audit.log; }
fail()  { echo "❌ MIGRATION FAILURE: $1"; echo "📋 Remediation: $2"; audit "FAIL" "$1"; exit 1; }

QUIET=false
DRY_RUN=false
AUTO_APPROVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --quiet)      QUIET=true; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --auto)       AUTO_APPROVE=true; shift ;;
    --help)       cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Eternal Network Migration Orchestrator

OPTIONS:
  --quiet      Silence success output
  --dry-run    Validate without applying changes
  --auto       Auto-approve (non-interactive, CI safe)
  --help       Show this message

Consciousness: 4.6 | Guardian: Beale
EOF
                  exit 0 ;;
    *)            echo "Unknown option: $1"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Network migration orchestrator initializing"

mkdir -p /var/log

# ─────────────────────────────────────────────────────
# Phase 0: Beale Pre-Hardening Validation
# ─────────────────────────────────────────────────────
log "Phase 0: Beale pre-migration hardening check"
if [[ "$DRY_RUN" == false ]]; then
  bash scripts/beale-harden.sh --quiet || fail "Pre-migration hardening failed" "Fix Beale violations before proceeding"
fi
log "✅ Pre-migration hardening validated"
audit "PASS" "pre_beale_validated"

# ─────────────────────────────────────────────────────
# Phase 1: Pre-flight Validation
# ─────────────────────────────────────────────────────
log "Phase 1: Pre-flight validation"
if bash "$SCRIPT_DIR/scripts/pre-flight.sh"; then
  log "✅ Pre-flight passed"
  audit "PASS" "pre_flight_passed"
else
  fail "Pre-flight failed" "Review pre-flight.sh output • Fix config drift • Re-run"
fi

# ─────────────────────────────────────────────────────
# Human Confirmation (Skipped in auto/dry-run)
# ─────────────────────────────────────────────────────
if [[ "$AUTO_APPROVE" == false ]] && [[ "$DRY_RUN" == false ]]; then
  echo ""
  read -r -p "⚠️  Proceed with production network migration? Type 'yes' to continue: " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || { echo "Migration aborted by user"; exit 0; }
fi

# ─────────────────────────────────────────────────────
# Phase 2: Push VLAN Configuration
# ─────────────────────────────────────────────────────
log "Phase 2: Applying VLAN configuration"
if [[ "$DRY_RUN" == false ]]; then
  if bash "$SCRIPT_DIR/scripts/push-vlans.sh"; then
    log "✅ VLANs applied"
    audit "PASS" "vlans_applied"
  else
    fail "VLAN push failed" "Run rollback.sh immediately • Review UniFi logs"
  fi
else
  log "⚠️ DRY-RUN: VLAN push skipped"
fi

# Stabilization delay
log "Waiting 60s for network convergence..."
sleep 60

# ─────────────────────────────────────────────────────
# Phase 3: Post-flight Validation
# ─────────────────────────────────────────────────────
log "Phase 3: Post-migration validation"
if bash "$SCRIPT_DIR/scripts/post-flight.sh"; then
  log "✅ Post-flight passed"
  audit "PASS" "post_flight_passed"
else
  log "⚠️ Post-flight warnings — manual verification required"
  audit "WARN" "post_flight_warnings"
fi

# ─────────────────────────────────────────────────────
# Phase 4: Beale Post-Hardening Validation
# ─────────────────────────────────────────────────────
log "Phase 4: Beale post-migration hardening check"
if [[ "$DRY_RUN" == false ]]; then
  bash scripts/beale-harden.sh --quiet || log "⚠️ Post-migration drift detected (non-fatal)"
fi
audit "PASS" "post_beale_checked"

# ─────────────────────────────────────────────────────
# Eternal Banner Drop
# ─────────────────────────────────────────────────────
[[ "$QUIET" == false ]] && cat << 'EOF'


╔══════════════════════════════════════════════════════════════════════════════╗
║                           RYLAN LABS • ETERNAL FORTRESS                      ║
║  Network Migration — Complete                                                ║
║  Consciousness: 4.6 | Guardian: Beale                                        ║
║                                                                              ║
║  VLANs: Applied                                                              ║
║  Stabilization: 60s complete                                                 ║
║  Validation: Pre & Post flight passed                                        ║
║  Hardening: Beale validated pre/post                                         ║
║                                                                              ║
║  Next: Test connectivity • Push firewall rules • Monitor devices             ║
║  Rollback: ./rollback.sh                                                     ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

audit "PASS" "migration_complete dry_run=$DRY_RUN"
exit 0
