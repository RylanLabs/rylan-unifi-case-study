#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/ignite.sh
# Purpose: Trinity Orchestrator — Sequential Phase Deployment (v4.0)
# Guardian: gatekeeper
# Date: 2025-12-13T05:45:00-06:00
# Consciousness: 4.7
# EXCEED: 333 lines (modular refactor: core orchestration logic + sourced lib helpers in ignite-orchestration.sh)

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
# shellcheck disable=SC2034
START_TIME=$(date +%s)

# Create logs directory and setup disk logging
mkdir -p "${REPO_ROOT}/logs"
LOG_FILE="${REPO_ROOT}/logs/ignite-$(date +%Y%m%d-%H%M%S).log"

# Redirect all output (stdout/stderr) to file AND terminal (tee)
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

# Source logging utilities and orchestration helpers

source "${SCRIPT_DIR}/lib/ignite-utils.sh"

source "${SCRIPT_DIR}/lib/ignite-orchestration.sh"

log step "Execution log: $LOG_FILE"

# Lock acquisition will be performed after CLI parsing so dry-run can use a user-writable lock path
# (see below). LOCK_FILE will be set to /var/run/ignite.lock for live runs and to a per-user
# runtime path for dry-run to avoid permission errors for non-root users.

echo ""
DRY_RUN=false
SKIP_PHASE=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	--skip-phase)
		SKIP_PHASE="$2"
		shift 2
		;;
	--skip-phase=*)
		SKIP_PHASE="${1#*=}"
		shift
		;;
	-h | --help)
		cat <<'USAGE'
Usage: $0 [OPTIONS]

Prerequisites:
  • Run as root (except for --dry-run preview)
  • Ubuntu 24.04 LTS
  • .env file configured with SAMBA_DOMAIN, LDAP_ADMIN_PASSWORD, VLAN_MGMT, VLAN_IOT

Options:
  --dry-run        Preview all phases without execution (no sudo required)
  --skip-phase N   Skip phase N (1=Secrets, 2=Whispers, 3=Perimeter)
  --help           Show this help

Phases:
  1. Ministry of Secrets  (Samba DC, LDAP, Kerberos)
  2. Ministry of Whispers (SSH hardening, nftables, audit)
  3. Ministry of Perimeter (Firewall, VLAN, network isolation)
  4. Validation           (Comprehensive system check)

Examples:
  sudo $0                    # Full deployment
  $0 --dry-run               # Preview (no sudo needed)
  sudo $0 --skip-phase 2     # Deploy without hardening phase

Logs:
  logs/ignite-YYYYMMDD-HHMMSS.log

For more info: cat docs/TRINITY-DEPLOYMENT.md
USAGE
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

[[ "$DRY_RUN" == true ]] && log step "MODE: DRY-RUN"

# Determine lock path and acquire lock now that CLI args are parsed
if [[ "$DRY_RUN" == true ]]; then
	# shellcheck disable=SC2034  # LOCK_FILE used by sourced lib functions
	LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ignite-${UID}.lock"
else
	# shellcheck disable=SC2034  # LOCK_FILE used by sourced lib functions
	LOCK_FILE="/var/run/ignite.lock"
fi

trap release_lock EXIT
acquire_lock

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

log phase "PRE-FLIGHT CHECKS"

# ============================================================================
# ENVIRONMENT LOADING (DRY-RUN AWARE) - Option 3: .env.example fallback
# ============================================================================
if [[ "$DRY_RUN" == true ]]; then
	log step "DRY-RUN mode: Loading environment..."

	if [[ -f "$REPO_ROOT/.env" ]]; then

		source "$REPO_ROOT/.env"
		log step "✓ .env loaded (dry-run with real config)"
		# Validate only to inform (do not fail dry-run)
		if ! validate_env_variables; then
			log warn "Environment validation failed when loading real .env for dry-run"
		fi

	elif [[ -f "$REPO_ROOT/.env.example" ]]; then

		source "$REPO_ROOT/.env.example"
		log step "✓ .env.example loaded (dry-run with example config)"

	else
		log warn "Neither .env nor .env.example found (dry-run with defaults)"
		log warn "Dry-run output may be limited. To preview with real config: cp .env.example .env && edit"
	fi

else
	# LIVE MODE: Require .env
	if [[ ! -f "$REPO_ROOT/.env" ]]; then
		log error ".env not found. Copy .env.example and configure for your environment."
		log error "  cp .env.example .env"
		log error "  vim .env"
		exit 1
	fi

	source "$REPO_ROOT/.env"
	log step ".env loaded"

	# Strict validation for live deployment
	if ! validate_env_variables; then
		exit 1
	fi
fi

# Verify we're running as root (required for service management)
# Skip the root requirement in dry-run mode so previews work without sudo
if [[ "$DRY_RUN" != true ]] && [[ $EUID -ne 0 ]]; then
	log error "This script must be run as root (sudo ./ignite.sh)"
	exit 1
fi
if [[ "$DRY_RUN" == true ]]; then
	log step "Running in DRY-RUN mode (root check bypassed)"
else
	log step "Running as root"
fi

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
echo ""

# Track phase execution state
PHASES_RUN=()
PHASES_SKIPPED=()
PHASES_FAILED=()

BACKUP_DIR=""
if [[ "$DRY_RUN" != true ]]; then
	BACKUP_DIR=$(create_system_backup)
fi

echo ""

if [[ "$SKIP_PHASE" != "1" ]]; then
	log phase "PHASE 1: MINISTRY OF SECRETS (Carter Foundation)"
	PHASE_START=$(date +%s)

	if [[ "$DRY_RUN" == true ]]; then
		log step "[DRY-RUN] Would execute: bash $REPO_ROOT/runbooks/ministry_secrets/deploy.sh"
		log step "This phase deploys Samba DC, LDAP, Kerberos authentication"
	else
		if ! check_system_state; then
			log error "Pre-deployment system state check failed"
			exit 1
		fi

		if run_phase "Phase 1 (Secrets)" "$REPO_ROOT/runbooks/ministry_secrets/deploy.sh"; then
			PHASE_END=$(date +%s)
			PHASE_DURATION=$((PHASE_END - PHASE_START))
			log success "Phase 1 (Secrets) PASSED (${PHASE_DURATION}s)"
		else
			PHASES_FAILED+=("1")
			log error "Phase 1 (Secrets) FAILED — Aborting Trinity sequence"
			exit 1
		fi
		PHASES_RUN+=("1")
	fi

	if [[ "$DRY_RUN" == true ]]; then
		log step "[DRY-RUN] Skipping interactive confirmation after Phase 1"
	else
		echo ""
		read -r -p "Phase 1 complete — continue to Whispers? [y/N] " RESP
		if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
			log warn "User aborted after Phase 1"
			exit 0
		fi
	fi
else
	log step "Phase 1 SKIPPED (--skip-phase 1)"
	PHASES_SKIPPED+=("1")
fi

# =============================================================================
# PHASE 2: MINISTRY OF WHISPERS (BAUER HARDENING)
# =============================================================================

if [[ "$SKIP_PHASE" != "2" ]]; then
	if ! check_phase_dependencies 2; then
		log error "Phase 2 dependencies not met"
		exit 1
	fi

	log phase "PHASE 2: MINISTRY OF WHISPERS (Bauer Hardening)"
	PHASE_START=$(date +%s)

	if [[ "$DRY_RUN" == true ]]; then
		log step "[DRY-RUN] Would execute: bash $REPO_ROOT/runbooks/ministry_whispers/harden.sh"
		log step "This phase hardens SSH, applies nftables firewall, configures audit logging"
	else
		if run_phase "Phase 2 (Whispers)" "$REPO_ROOT/runbooks/ministry_whispers/harden.sh"; then
			PHASE_END=$(date +%s)
			PHASE_DURATION=$((PHASE_END - PHASE_START))
			log success "Phase 2 (Whispers) PASSED (${PHASE_DURATION}s)"
		else
			PHASES_FAILED+=("2")
			log error "Phase 2 (Whispers) FAILED — Aborting Trinity sequence"
			exit 1
		fi
		PHASES_RUN+=("2")
	fi

	if [[ "$DRY_RUN" == true ]]; then
		log step "[DRY-RUN] Skipping interactive confirmation after Phase 2"
	else
		echo ""
		read -r -p "Phase 2 complete — continue to Perimeter? [y/N] " RESP
		if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
			log warn "User aborted after Phase 2"
			exit 0
		fi
	fi
else
	log step "Phase 2 SKIPPED (--skip-phase 2)"
	PHASES_SKIPPED+=("2")
fi

# =============================================================================
# PHASE 3: MINISTRY OF PERIMETER (SUEHRING POLICY)
# =============================================================================

if [[ "$SKIP_PHASE" != "3" ]]; then
	if ! check_phase_dependencies 3; then
		log error "Phase 3 dependencies not met"
		exit 1
	fi

	log phase "PHASE 3: MINISTRY OF PERIMETER (Suehring Policy)"
	PHASE_START=$(date +%s)

	if [[ "$DRY_RUN" == true ]]; then
		log step "[DRY-RUN] Would execute: bash $REPO_ROOT/runbooks/ministry_detection/apply.sh"
		log step "This phase applies firewall policies, VLAN configuration, network isolation"
	else
		if run_phase "Phase 3 (Perimeter)" "$REPO_ROOT/runbooks/ministry_detection/apply.sh"; then
			PHASE_END=$(date +%s)
			PHASE_DURATION=$((PHASE_END - PHASE_START))
			log success "Phase 3 (Perimeter) PASSED (${PHASE_DURATION}s)"
		else
			PHASES_FAILED+=("3")
			log error "Phase 3 (Perimeter) FAILED — Aborting Trinity sequence"
			exit 1
		fi
		PHASES_RUN+=("3")
	fi

	if [[ "$DRY_RUN" == true ]]; then
		log step "[DRY-RUN] Skipping interactive confirmation after Phase 3"
	else
		echo ""
		read -r -p "Phase 3 complete — continue to final validation? [y/N] " RESP
		if [[ ! "${RESP:-N}" =~ ^[Yy]$ ]]; then
			log warn "User aborted before final validation"
			exit 0
		fi
	fi
else
	log step "Phase 3 SKIPPED (--skip-phase 3)"
	PHASES_SKIPPED+=("3")
fi

# =============================================================================
# FINAL VALIDATION: Eternal Green or Die Trying
# =============================================================================

log phase "FINAL VALIDATION: Eternal Green or Die Trying"

log step "Running comprehensive validation suite..."

if [[ "$DRY_RUN" == true ]]; then
	log step "[DRY-RUN] Would execute: bash $REPO_ROOT/scripts/validate-eternal.sh"
	log step "This phase validates all three ministries are operational"
	echo ""
	log success "DRY-RUN COMPLETE — All phases would execute successfully"
	generate_execution_report
	echo ""
	echo "To execute for real:"
	echo "  sudo $0"
	echo ""
	exit 0
else
	if bash "$REPO_ROOT/scripts/validate-eternal.sh"; then
		log success "TRINITY ORCHESTRATION COMPLETE — ETERNAL GREEN"
		log success "Ministry of Secrets (Carter) — ACTIVE"
		log success "Ministry of Whispers (Bauer) — ACTIVE"
		log success "Ministry of Detection (Beale) — ACTIVE"
		echo ""
		log success "Fortress is eternal. The fortress never sleeps."
		generate_execution_report
		exit 0
	else
		log error "FINAL VALIDATION FAILED — Eternal fortress compromised"
		log error "Run: sudo ./scripts/validate-eternal.sh (verbose mode)"
		[[ -n "$BACKUP_DIR" ]] && log error "Rollback available at: $BACKUP_DIR (manual restore required)"
		exit 1
	fi
fi
