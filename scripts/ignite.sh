#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/ignite.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6
# Excess: 189 lines — 6 functions

# Trinity Orchestrator — Sequential Phase Enforcement (v4.0)
# Carter (Secrets) -> Bauer (Whispers) -> Beale (Detection) -> Validate
# Zero concurrency. Exit-on-fail. Junior-at-3-AM deployable (<45 min).

cat <<'BANNER'
================================================================================
                        TRINITY ORCHESTRATOR v4.0
                 Sequential Phase Deployment (Zero Concurrency)

  Phase 1: Ministry of Secrets (Carter)  -> Samba / LDAP / Kerberos
  Phase 2: Ministry of Whispers (Bauer)  -> SSH / nftables / audit
  Phase 3: Ministry of Detection (Beale) -> Policy / VLAN / Audit
  Final:   Validation (eternal green or die trying)
================================================================================
BANNER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
START_TIME=$(date +%s)

# Source logging utilities
source "${SCRIPT_DIR}/lib/ignite-utils.sh"

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

log phase "PRE-FLIGHT CHECKS"

# Load environment
if [[ ! -f "$REPO_ROOT/.env" ]]; then
  log error ".env not found. Copy .env.example and configure for your environment."
  exit 1
fi
# shellcheck disable=SC1091
source "$REPO_ROOT/.env"
log step ".env loaded"

# Verify we're running as root (required for service management)
if [[ $EUID -ne 0 ]]; then
  log error "This script must be run as root (sudo ./ignite.sh)"
  exit 1
fi
log step "Running as root"

# Verify runbooks exist
if [[ ! -d "$REPO_ROOT/runbooks/ministry_secrets" ]]; then
  log error "Ministry of Secrets runbook not found"
  exit 1
fi
if [[ ! -d "$REPO_ROOT/runbooks/ministry_whispers" ]]; then
  log error "Ministry of Whispers runbook not found"
  exit 1
fi
if [[ ! -d "$REPO_ROOT/runbooks/ministry_detection" ]]; then
  log error "Ministry of Perimeter runbook not found"
  exit 1
fi
log step "All Ministry runbooks present"

# Verify Ubuntu 24.04 LTS
if ! grep -q "24.04" /etc/os-release 2>/dev/null; then
  log warn "Not Ubuntu 24.04 LTS (some components may not work as documented)"
fi
log step "OS check passed"

# =============================================================================
# PHASE 1: MINISTRY OF SECRETS (CARTER FOUNDATION)
# =============================================================================

log phase "PHASE 1: MINISTRY OF SECRETS (Carter Foundation)"

if bash "$REPO_ROOT/runbooks/ministry_secrets/deploy.sh"; then
  log success "Phase 1 (Secrets) PASSED"
else
  log error "Phase 1 (Secrets) FAILED — Aborting Trinity sequence"
  exit 1
fi

# Confirm before proceeding
echo ""
read -r -p "Phase 1 complete — continue to Whispers? [y/N] " RESP
if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
  log warn "User aborted after Phase 1"
  exit 0
fi

# =============================================================================
# PHASE 2: MINISTRY OF WHISPERS (BAUER HARDENING)
# =============================================================================

log phase "PHASE 2: MINISTRY OF WHISPERS (Bauer Hardening)"

if bash "$REPO_ROOT/runbooks/ministry_whispers/harden.sh"; then
  log success "Phase 2 (Whispers) PASSED"
else
  log error "Phase 2 (Whispers) FAILED — Aborting Trinity sequence"
  exit 1
fi

# Confirm before proceeding
echo ""
read -r -p "Phase 2 complete — continue to Perimeter? [y/N] " RESP
if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
  log warn "User aborted after Phase 2"
  exit 0
fi

# =============================================================================
# PHASE 3: MINISTRY OF PERIMETER (SUEHRING POLICY)
# =============================================================================

log phase "PHASE 3: MINISTRY OF PERIMETER (Suehring Policy)"

if bash "$REPO_ROOT/runbooks/ministry_detection/apply.sh"; then
  log success "Phase 3 (Perimeter) PASSED"
else
  log error "Phase 3 (Perimeter) FAILED — Aborting Trinity sequence"
  exit 1
fi

# Confirm before final validation
echo ""
read -r -p "Phase 3 complete — continue to final validation? [y/N] " RESP
if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
  log warn "User aborted before final validation"
  exit 0
fi

# =============================================================================
# FINAL VALIDATION: Eternal Green or Die Trying
# =============================================================================

log phase "FINAL VALIDATION: Eternal Green or Die Trying"

log step "Running comprehensive validation suite..."

if bash "$REPO_ROOT/scripts/validate-eternal.sh"; then
  log success "TRINITY ORCHESTRATION COMPLETE — ETERNAL GREEN"
  log success "Ministry of Secrets (Carter) — ACTIVE"
  log success "Ministry of Whispers (Bauer) — ACTIVE"
  log success "Ministry of Detection (Beale) — ACTIVE"
  echo ""
  log success "Fortress is eternal. The fortress never sleeps."
  exit 0
else
  log error "FINAL VALIDATION FAILED — Eternal fortress compromised"
  log error "Run: sudo ./validate-eternal.sh (verbose mode)"
  exit 1
fi
