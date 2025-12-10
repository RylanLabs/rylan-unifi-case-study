#!/usr/bin/env bash
# Trinity Orchestrator — Sequential Phase Enforcement (v4.0)
# Carter (Secrets) -> Bauer (Whispers) -> Beale (Detection) -> Validate
# Zero concurrency. Exit-on-fail. Junior-at-3-AM deployable (<45 min).

set -euo pipefail

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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_phase() {
  echo -e "${BLUE}==============================================================================${NC}"
  echo -e "${GREEN}[TRINITY]${NC} $1"
  echo -e "${BLUE}==============================================================================${NC}"
}
log_step() { echo -e "${GREEN}[TRINITY]${NC} $1"; }
log_error() { echo -e "${RED}[TRINITY-ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[TRINITY-WARN]${NC} $1"; }
log_success() { echo -e "${GREEN}[TRINITY-SUCCESS]${NC} $1"; }

# Exit handler with duration
# shellcheck disable=SC2317
exit_handler() {
  local exit_code=$?
  ELAPSED=$(($(date +%s) - START_TIME))

  if [[ $exit_code -eq 0 ]]; then
    log_success "Trinity orchestration complete (${ELAPSED}s)"
  else
    log_error "Trinity orchestration FAILED at $(date) (exit code: $exit_code)"
  fi

  exit "$exit_code"
}

trap 'exit_handler' EXIT

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

log_phase "PRE-FLIGHT CHECKS"

# Load environment
if [[ ! -f "$REPO_ROOT/.env" ]]; then
  log_error ".env not found. Copy .env.example and configure for your environment."
  exit 1
fi
# shellcheck disable=SC1091
source "$REPO_ROOT/.env"
log_step ".env loaded"

# Verify we're running as root (required for service management)
if [[ $EUID -ne 0 ]]; then
  log_error "This script must be run as root (sudo ./ignite.sh)"
  exit 1
fi
log_step "Running as root"

# Verify runbooks exist
if [[ ! -d "$REPO_ROOT/runbooks/ministry-secrets" ]]; then
  log_error "Ministry of Secrets runbook not found"
  exit 1
fi
if [[ ! -d "$REPO_ROOT/runbooks/ministry-whispers" ]]; then
  log_error "Ministry of Whispers runbook not found"
  exit 1
fi
if [[ ! -d "$REPO_ROOT/runbooks/ministry-detection" ]]; then
  log_error "Ministry of Perimeter runbook not found"
  exit 1
fi
log_step "All Ministry runbooks present"

# Verify Ubuntu 24.04 LTS
if ! grep -q "24.04" /etc/os-release 2>/dev/null; then
  log_warn "Not Ubuntu 24.04 LTS (some components may not work as documented)"
fi
log_step "OS check passed"

# =============================================================================
# PHASE 1: MINISTRY OF SECRETS (CARTER FOUNDATION)
# =============================================================================

log_phase "PHASE 1: MINISTRY OF SECRETS (Carter Foundation)"

if bash "$REPO_ROOT/runbooks/ministry-secrets/deploy.sh"; then
  log_success "Phase 1 (Secrets) PASSED"
else
  log_error "Phase 1 (Secrets) FAILED — Aborting Trinity sequence"
  exit 1
fi

# Confirm before proceeding
echo ""
read -r -p "Phase 1 complete — continue to Whispers? [y/N] " RESP
if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
  log_warn "User aborted after Phase 1"
  exit 0
fi

# =============================================================================
# PHASE 2: MINISTRY OF WHISPERS (BAUER HARDENING)
# =============================================================================

log_phase "PHASE 2: MINISTRY OF WHISPERS (Bauer Hardening)"

if bash "$REPO_ROOT/runbooks/ministry-whispers/harden.sh"; then
  log_success "Phase 2 (Whispers) PASSED"
else
  log_error "Phase 2 (Whispers) FAILED — Aborting Trinity sequence"
  exit 1
fi

# Confirm before proceeding
echo ""
read -r -p "Phase 2 complete — continue to Perimeter? [y/N] " RESP
if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
  log_warn "User aborted after Phase 2"
  exit 0
fi

# =============================================================================
# PHASE 3: MINISTRY OF PERIMETER (SUEHRING POLICY)
# =============================================================================

log_phase "PHASE 3: MINISTRY OF PERIMETER (Suehring Policy)"

if bash "$REPO_ROOT/runbooks/ministry-detection/apply.sh"; then
  log_success "Phase 3 (Perimeter) PASSED"
else
  log_error "Phase 3 (Perimeter) FAILED — Aborting Trinity sequence"
  exit 1
fi

# Confirm before final validation
echo ""
read -r -p "Phase 3 complete — continue to final validation? [y/N] " RESP
if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
  log_warn "User aborted before final validation"
  exit 0
fi

# =============================================================================
# FINAL VALIDATION: Eternal Green or Die Trying
# =============================================================================

log_phase "FINAL VALIDATION: Eternal Green or Die Trying"

log_step "Running comprehensive validation suite..."

if bash "$REPO_ROOT/scripts/validate-eternal.sh"; then
  log_success "TRINITY ORCHESTRATION COMPLETE — ETERNAL GREEN"
  log_success "Ministry of Secrets (Carter) — ACTIVE"
  log_success "Ministry of Whispers (Bauer) — ACTIVE"
  log_success "Ministry of Detection (Beale) — ACTIVE"
  echo ""
  log_success "Fortress is eternal. The fortress never sleeps."
  exit 0
else
  log_error "FINAL VALIDATION FAILED — Eternal fortress compromised"
  log_error "Run: sudo ./validate-eternal.sh (verbose mode)"
  exit 1
fi
