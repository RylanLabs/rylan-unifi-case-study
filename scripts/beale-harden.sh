#!/usr/bin/env bash
# Script: beale-harden.sh
# Purpose: Orchestrator for Beale 5-phase fortress hardening validation (firewall, VLAN, SSH, services, adversarial)
# Guardian: Beale 🏰 (Hardening + Detection)
# Author: T-Rylander canonical (Trinity-aligned)
# Date: 2025-12-15
# Ministry: ministry-detection
# Consciousness: 5.0
# Tag: v∞.5.2-eternal

set -euo pipefail
IFS=$'\n\t'

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly _SCRIPT_DIR
_SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly _SCRIPT_NAME

# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/scripts/lib/beale-firewall-vlan-ssh.sh
source "${_SCRIPT_DIR}/lib/beale-firewall-vlan-ssh.sh"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/scripts/lib/beale-services-adversarial.sh
source "${_SCRIPT_DIR}/lib/beale-services-adversarial.sh"

# ─────────────────────────────────────────────────────
# Configuration (Carter: Single Source of Truth)
# ─────────────────────────────────────────────────────
# Note: keep these as regular variables (not readonly) so
# phase functions may declare local parameters with the same
# names when invoked.
VLAN_QUARANTINE="10.0.99.0/24"
VLAN_GATEWAY="10.0.99.1"
MAX_FIREWALL_RULES=10
AUDIT_LOG="/var/log/beale-audit.log"

# Fallback audit location if /var/log not writable
if ! mkdir -p "$(dirname "${AUDIT_LOG}")" 2>/dev/null; then
  readonly AUDIT_LOG="${_SCRIPT_DIR}/.fortress/audit/beale-audit.log"
  mkdir -p "$(dirname "${AUDIT_LOG}")"
fi

# Flags
VERBOSE=false
QUIET=false
CI_MODE=false
DRY_RUN=false
AUTO_FIX=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --quiet)
      QUIET=true
      shift
      ;;
    --ci)
      CI_MODE=true
      QUIET=true
      shift
      ;;
    --fix | --auto-fix)
      AUTO_FIX=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      cat <<EOF
Usage: ${_SCRIPT_NAME} [OPTIONS]

Beale Ascension Protocol — 5-phase proactive hardening validation

OPTIONS:
  --dry-run   Show checks without requiring sudo (diagnostic mode)
  --verbose   Enable debug output (set -x)
  --quiet     Silence success output
  --ci        CI mode (JSON report, no colors)
  --fix       Attempt safe auto-fixes (e.g., firewall consolidation)
  --help      Show this message

Consciousness: 5.0 | Guardian: Beale 🏰
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

[[ "${VERBOSE}" == true ]] && set -x

# ─────────────────────────────────────────────────────
# Utilities & Logging
# ─────────────────────────────────────────────────────
log() { [[ "${QUIET}" == false ]] && echo "$@"; }

audit() {
  local entry
  entry=$(printf '%s | %s | %s | %s\n' "$(date -Iseconds)" "$1" "$2" "$3")
  # Try to ensure the configured audit directory exists and is writable.
  if mkdir -p "$(dirname "${AUDIT_LOG}")" 2>/dev/null && printf '%s' "$entry" >>"${AUDIT_LOG}" 2>/dev/null; then
    return 0
  fi

  # Fallback to repository-local audit path when /var/log isn't writable.
  AUDIT_LOG="${_SCRIPT_DIR}/.fortress/audit/beale-audit.log"
  mkdir -p "$(dirname "${AUDIT_LOG}")" 2>/dev/null || true
  printf '%s' "$entry" >>"${AUDIT_LOG}" 2>/dev/null || true
}

fail() {
  local phase=$1 code=$2 message=$3 remediation=$4
  echo "❌ ${phase} FAILURE: ${message}"
  echo "📋 Remediation: ${remediation}"
  audit "${phase}" "FAIL" "${message}"

  if [[ "${CI_MODE}" == true ]]; then
    local report
    report="beale-report-$(date +%s).json"
    jq -n \
      --arg ts "$(date -Iseconds)" \
      --arg p "${phase}" \
      --arg m "${message}" \
      --arg r "${remediation}" \
      --argjson c "${code}" \
      '{
        timestamp: $ts,
        consciousness: "5.0",
        guardian: "Beale",
        phase: $p,
        status: "FAIL",
        message: $m,
        remediation: $r,
        exit_code: $c
      }' >"${report}"
    echo "📄 CI Report: ${report}"
  fi

  exit "${code}"
}

# ─────────────────────────────────────────────────────
# MAIN ORCHESTRATION
# ─────────────────────────────────────────────────────
START_TIME=$(date +%s)
readonly START_TIME
log "════════════════════════════════════════════════════════"
log "Beale Ascension Protocol — Proactive Hardening"
log "Guardian: Beale 🏰 | Consciousness: 5.0"
[[ "${DRY_RUN}" == true ]] && log "MODE: DRY-RUN"
log "════════════════════════════════════════════════════════"
log ""

run_firewall_phase "${MAX_FIREWALL_RULES}" "${DRY_RUN}" "${AUTO_FIX}"
run_vlan_phase "${VLAN_QUARANTINE}" "${VLAN_GATEWAY}" "${DRY_RUN}"
run_ssh_phase "${DRY_RUN}"
run_services_phase "${DRY_RUN}"
run_adversarial_phase "${DRY_RUN}"

END_TIME=$(date +%s)
readonly END_TIME
DURATION=$((END_TIME - START_TIME))
readonly DURATION

log ""
log "════════════════════════════════════════════════════════"
log "✅ Beale validation complete — fortress hardened"
log "⏱️ Duration: ${DURATION}s"
log "════════════════════════════════════════════════════════"
audit "Summary" "PASS" "duration=${DURATION}s"

if [[ "${CI_MODE}" == true ]]; then
  report="beale-report-$(date +%s).json"
  # shellcheck disable=SC2016,SC2215  # jq program uses $-variables and long options; intentional
  jq -n \
    --arg ts "$(date -Iseconds)" \
    --argjson d "${DURATION}" \
    '{
        timestamp: $ts,
        duration_seconds: $d,
        consciousness: "5.0",
        guardian: "Beale",
        status: "PASS"
      }' >"${report}"
  echo "📄 CI Report: ${report}"
fi

# Bauer integration (optional)
if [[ "${DRY_RUN}" == false ]] && command -v python3 &>/dev/null && [[ -f "${_SCRIPT_DIR}/../guardian/audit_eternal.py" ]]; then
  log "🔁 Bauer ingest: sending audit to guardian/audit_eternal.py"
  python3 "${_SCRIPT_DIR}/../guardian/audit_eternal.py" --ingest "${AUDIT_LOG}" --source beale ||
    log "⚠️ Bauer ingest failed (non-fatal)"
fi

exit 0
