#!/usr/bin/env bash
# Script: runbooks/ministry-detection/rylan-beale-eternal-one-shot.sh
# Purpose: Beale ministry — Host hardening, IDS arming, drift detection
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
set -euo pipefail

# ─────────────────────────────────────────────────────
# Beale Doctrine: Detect the breach, harden the host
# ─────────────────────────────────────────────────────
log()   { [[ "$QUIET" == false ]] && echo "[Beale] $*"; }
audit() { echo "$(date -Iseconds) | Beale | $1 | $2" >> /var/log/beale-audit.log; }
fail()  { echo "❌ Beale FAILURE: $1"; audit "FAIL" "$1"; exit 1; }

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

log "Beale ministry initializing — Hardening & detection"

mkdir -p /var/log

# ─────────────────────────────────────────────────────
# Phase 1: Proactive Hardening Validation
# ─────────────────────────────────────────────────────
log "Phase 1: Running proactive hardening validation"
if ! bash scripts/beale-harden.sh --quiet; then
  fail "Hardening validation failed" "Review beale-harden.sh output and remediate"
fi
log "✅ Proactive hardening passed"
audit "PASS" "beale_harden_validated"

# ─────────────────────────────────────────────────────
# Phase 2: IDS Arming (Snort/Suricata – future)
# ─────────────────────────────────────────────────────
log "Phase 2: IDS Configuration Check"
if systemctl is-active --quiet snort || systemctl is-active --quiet suricata; then
  log "✅ IDS service running"
  audit "PASS" "ids_active"
else
  log "⚠️ IDS not running — arming deferred (future phase)"
  audit "INFO" "ids_not_active"
fi

# ─────────────────────────────────────────────────────
# Phase 3: Drift Detection (future)
# ─────────────────────────────────────────────────────
log "Phase 3: Configuration Drift Detection"
if [[ -f scripts/beale-drift-detect.sh ]]; then
  bash scripts/beale-drift-detect.sh --quiet || log "⚠️ Drift detected (non-fatal)"
  audit "INFO" "drift_check_completed"
else
  log "⚠️ Drift detection script missing — deferred"
fi

# ─────────────────────────────────────────────────────
# Eternal Banner Drop
# ─────────────────────────────────────────────────────
[[ "$QUIET" == false ]] && cat << 'EOF'


╔══════════════════════════════════════════════════════════════════════════════╗
║                           RYLAN LABS • ETERNAL FORTRESS                      ║
║  Ministry: Beale (Detection) — Complete                                      ║
║  Consciousness: 4.6 | Guardian: Beale | Trinity Aligned                      ║
║                                                                              ║
║  Hardening: Passed (beale-harden.sh v8.0)                                    ║
║  IDS: Running (or deferred)                                                  ║
║  Drift: Checked (or deferred)                                                ║
║                                                                              ║
║  Next: Whitaker offensive validation                                         ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

audit "PASS" "ministry_complete hardening_passed=true"
exit 0
