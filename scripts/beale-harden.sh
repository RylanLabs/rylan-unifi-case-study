#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/beale-harden.sh
# Purpose: Orchestrator for fortress hardening validation (Phases 1-5)
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
# Exit Codes: 0=pass, 1=firewall, 2=vlan, 3=ssh, 4=services, 5=adversarial

# ─────────────────────────────────────────────────────
# Configuration (Carter: Single Source of Truth)
# ─────────────────────────────────────────────────────
VLAN_QUARANTINE="10.0.99.0/24"
VLAN_GATEWAY="10.0.99.1"
MAX_FIREWALL_RULES=10
AUDIT_LOG="/var/log/beale-audit.log"

if [[ -w "$(dirname "$AUDIT_LOG")" ]]; then
  mkdir -p "$(dirname "$AUDIT_LOG")"
else
  AUDIT_LOG="$(pwd)/.fortress/audit/beale-audit.log"
  mkdir -p "$(dirname "$AUDIT_LOG")"
fi

# Flags
VERBOSE=false
QUIET=false
CI_MODE=false
DRY_RUN=false
AUTO_FIX=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose) VERBOSE=true; shift ;;
    --quiet)   QUIET=true; shift ;;
    --ci)      CI_MODE=true; QUIET=true; shift ;;
    --fix|--auto-fix) AUTO_FIX=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help)    cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Beale Hardening Protocol — Proactive validation

OPTIONS:
  --dry-run   Show checks without sudo (diagnostic mode)
  --verbose   Enable debug output (set -x)
  --quiet     Silence success output
  --ci        CI mode (JSON report, no colors)
  --fix       Attempt safe auto-fixes (firewall consolidation)
  --help      Show this message

Consciousness: 4.6 | Guardian: Beale
EOF
               exit 0 ;;
    *)         echo "Unknown option: $1"; exit 1 ;;
  esac
done

[[ "$VERBOSE" == true ]] && set -x

# ─────────────────────────────────────────────────────
# Utilities & Logging
# ─────────────────────────────────────────────────────
log()   { [[ "$QUIET" == false ]] && echo "$@"; }
audit() { mkdir -p "$(dirname "$AUDIT_LOG")"; echo "$(date -Iseconds) | $1 | $2 | $3" >> "$AUDIT_LOG"; }
## shellcheck disable=SC2317
fail() {
  local phase=$1 code=$2 message=$3 remediation=$4
  echo "❌ $phase FAILURE: $message"
  echo "📋 Remediation: $remediation"
  audit "$phase" "FAIL" "$message"
  if [[ "$CI_MODE" == true ]]; then
    REPORT="beale-report-$(date +%s).json"
    cat > "$REPORT" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "consciousness": "4.6",
  "guardian": "Beale",
  "phase": "$phase",
  "status": "FAIL",
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "remediation": "$(echo "$remediation" | sed 's/"/\\"/g')",
  "exit_code": $code
}
EOF
    echo "📄 CI Report: $REPORT"
  fi
  exit "$code"
}

# ─────────────────────────────────────────────────────
# SOURCE MODULES
# ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/beale-firewall-vlan-ssh.sh"
source "${SCRIPT_DIR}/lib/beale-services-adversarial.sh"

# ─────────────────────────────────────────────────────
# MAIN ORCHESTRATION
# ─────────────────────────────────────────────────────
START_TIME=$(date +%s)
log "════════════════════════════════════════════════════════"
log "Beale Ascension Protocol — Proactive Hardening"
log "Guardian: Beale | Consciousness: 4.6"
[[ "$DRY_RUN" == true ]] && log "MODE: DRY-RUN"
log "════════════════════════════════════════════════════════"
log ""

# Run phases via modules
run_firewall_phase "$MAX_FIREWALL_RULES" "$DRY_RUN" "$AUTO_FIX"
run_vlan_phase "$VLAN_QUARANTINE" "$VLAN_GATEWAY" "$DRY_RUN"
run_ssh_phase "$DRY_RUN"
run_services_phase "$DRY_RUN"
run_adversarial_phase "$DRY_RUN"

# Summary
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
log ""
log "════════════════════════════════════════════════════════"
log "✅ Beale validation complete — fortress hardened"
log "⏱️ Duration: ${DURATION}s"
log "════════════════════════════════════════════════════════"
audit "Summary" "PASS" "duration=${DURATION}s"

# CI Artifact
if [[ "$CI_MODE" == true ]]; then
  REPORT="beale-report-$(date +%s).json"
  cat > "$REPORT" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "duration_seconds": $DURATION,
  "consciousness": "4.6",
  "guardian": "Beale",
  "status": "PASS"
}
EOF
  echo "📄 CI Report: $REPORT"
fi

# Bauer integration
if [[ "$DRY_RUN" == false ]] && command -v python3 &>/dev/null && [[ -f guardian/audit_eternal.py ]]; then
  log "🔁 Bauer ingest: sending audit to guardian/audit_eternal.py"
  python3 guardian/audit_eternal.py --ingest "$AUDIT_LOG" --source beale || log "⚠️ Bauer ingest failed"
fi

exit 0
