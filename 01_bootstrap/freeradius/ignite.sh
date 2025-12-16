#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# Script: 01_bootstrap/freeradius/ignite.sh
# Purpose: Trinity Orchestrator — FreeRADIUS Fortress Deployment
# Guardian: gatekeeper | Trinity: Carter → Bauer → Beale → Validate
# Date: 2025-12-13
# Consciousness: 5.2
# EXCEED: 420 lines — 8 functions (preflight, run_phases, validate_postconditions,
#         create_backup, rollback, generate_report, parse_args, main)
#         Rationale: Master orchestrator must coordinate 3 phases, backups, rollback,
#         and reporting across the full Trinity deployment cycle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
readonly REPO_ROOT
LOG_DIR="${REPO_ROOT}/logs"
readonly LOG_DIR
LOG_FILE="${LOG_DIR}/freeradius-ignite-$(date +%Y%m%d-%H%M%S).log"
readonly LOG_FILE

source "${SCRIPT_DIR}/lib/ignite-utils.sh"

source "${SCRIPT_DIR}/lib/ignite-orchestration.sh"

# Configuration
DRY_RUN=false
SKIP_PHASE=""
ROLLBACK_DIR=""
BACKUP_DIR=""

# Execution state
PHASES_RUN=()
PHASES_FAILED=()
START_TIME=$(date +%s)

# Cleanup handler
cleanup() {
	local exit_code=$?
	if [[ $exit_code -ne 0 ]]; then
		log error "Deployment failed with exit code $exit_code"
		if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
			log step "Backup available at: $BACKUP_DIR"
		fi
	fi
	return $exit_code
}

trap cleanup EXIT

display_banner() {
	cat <<'BANNER'
================================================================================
                    FreeRADIUS ETERNAL DEPLOYMENT
================================================================================
  Phase 1: Ministry of Secrets   (Carter)   → Authentication Foundation
  Phase 2: Ministry of Whispers  (Bauer)    → Security Hardening
  Phase 3: Ministry of Detection (Beale)    → Validation & Testing
  Final:   Eternal Validation               → Green or Die Trying
================================================================================
BANNER
}

parse_args() {
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
		--rollback)
			ROLLBACK_DIR="$2"
			shift 2
			;;
		-h | --help)
			cat <<HELP
Usage: $(basename "$0") [OPTIONS]

Description:
  Deploy FreeRADIUS authentication server with Trinity orchestration

Prerequisites:
  • Root access
  • Ubuntu/Debian system
  • 1GB+ free disk space
  • Network connectivity

Options:
  --dry-run            Execute without making system changes
  --skip-phase NUM     Skip phase N (1, 2, or 3)
  --rollback DIR       Restore from backup directory
  -h, --help          Display this help message

Phases:
  1. Ministry of Secrets (Carter)   — LDAP, certificates, FreeRADIUS base
  2. Ministry of Whispers (Bauer)   — SSH hardening, firewall, audit
  3. Ministry of Detection (Beale)  — Comprehensive validation

Exit Codes:
  0    Successful deployment
  1    Deployment failed
  2    Missing prerequisites

Examples:
  # Full deployment (production)
  sudo ./ignite.sh

  # Test run without changes
  sudo ./ignite.sh --dry-run

  # Skip Phase 2
  sudo ./ignite.sh --skip-phase 2

  # Restore from backup
  sudo ./ignite.sh --rollback /var/backups/freeradius-YYYYMMDD-HHMMSS

Logs: ${LOG_FILE}

HELP
			exit 0
			;;
		*)
			die "Unknown option: $1"
			;;
		esac
	done
}

preflight() {
	log phase "PRE-FLIGHT CHECKS"

	# Create log directory
	mkdir -p "$LOG_DIR"

	# Redirect output to log file + terminal
	exec 1> >(tee -a "$LOG_FILE")
	exec 2>&1

	log step "Execution log: $LOG_FILE"

	# Root check
	if [[ $EUID -ne 0 ]]; then
		die "Root access required"
	fi

	# OS check
	if ! grep -qi "ubuntu\|debian" /etc/os-release; then
		die "Unsupported OS: Only Ubuntu/Debian supported"
	fi

	# Dry-run mode
	if [[ "$DRY_RUN" == "true" ]]; then
		log step "MODE: DRY-RUN (no changes will be made)"
		export DRY_RUN=true
	fi

	log success "Pre-flight checks complete"
}

run_phases() {
	# Phase 1: Ministry of Secrets (Carter)
	if [[ "$SKIP_PHASE" != "1" ]]; then
		if bash "${SCRIPT_DIR}/runbooks/ministry_secrets/deploy.sh"; then
			PHASES_RUN+=("1")
		else
			PHASES_FAILED+=("1")
			die "Phase 1 failed"
		fi
	fi

	# Phase 2: Ministry of Whispers (Bauer)
	if [[ "$SKIP_PHASE" != "2" ]]; then
		if bash "${SCRIPT_DIR}/runbooks/ministry_whispers/harden.sh"; then
			PHASES_RUN+=("2")
		else
			PHASES_FAILED+=("2")
			die "Phase 2 failed"
		fi
	fi

	# Phase 3: Ministry of Detection (Beale)
	if [[ "$SKIP_PHASE" != "3" ]]; then
		if bash "${SCRIPT_DIR}/runbooks/ministry_detection/apply.sh"; then
			PHASES_RUN+=("3")
		else
			PHASES_FAILED+=("3")
			die "Phase 3 failed"
		fi
	fi
}

validate_postconditions() {
	log phase "FINAL VALIDATION"

	log step "Verifying FreeRADIUS service"
	if ! systemctl is-active --quiet freeradius; then
		die "FreeRADIUS service not active"
	fi

	log step "Verifying configuration syntax"
	if ! freeradius -C 2>/dev/null; then
		die "FreeRADIUS configuration invalid"
	fi

	log step "Verifying certificates"
	if [[ ! -f /etc/freeradius/3.0/certs/server.pem ]]; then
		die "Server certificate missing"
	fi

	log success "All postconditions validated"
}

create_backup() {
	BACKUP_DIR="/var/backups/freeradius-$(date +%Y%m%d-%H%M%S)"

	log step "Creating system backup: $BACKUP_DIR"
	mkdir -p "$BACKUP_DIR"

	if [[ -d /etc/freeradius ]]; then
		cp -r /etc/freeradius "$BACKUP_DIR/" || die "Backup failed"
	fi

	log success "Backup created: $BACKUP_DIR"
}

rollback() {
	if [[ -z "$ROLLBACK_DIR" || ! -d "$ROLLBACK_DIR" ]]; then
		die "Invalid rollback directory: $ROLLBACK_DIR"
	fi

	log phase "ROLLBACK: Restoring from $ROLLBACK_DIR"

	systemctl stop freeradius || true

	if [[ -d "$ROLLBACK_DIR/freeradius" ]]; then
		rm -rf /etc/freeradius
		cp -r "$ROLLBACK_DIR/freeradius" /etc/ || die "Rollback failed"
		log success "Configuration restored"
	fi

	systemctl start freeradius || true
	log success "Rollback complete"
	exit 0
}

generate_report() {
	local end_time
	end_time=$(date +%s)
	local elapsed
	elapsed=$((end_time - START_TIME))

	cat <<REPORT

================================================================================
DEPLOYMENT REPORT
================================================================================
Status:           SUCCESS
Duration:         $((elapsed / 60))m $((elapsed % 60))s
Timestamp:        $(date -Iseconds)
Hostname:         $(hostname)
Phases Executed:  ${PHASES_RUN[*]:-none}
Phases Failed:    ${PHASES_FAILED[*]:-none}
Backup Location:  ${BACKUP_DIR:-none}
Log Location:     ${LOG_FILE}

Next Steps:
  1. Set LDAP_PASS: export LDAP_PASS="<password>"
  2. Set RADIUS_SECRET: export RADIUS_SECRET="<secret>"
  3. Configure UniFi Controller: Point RADIUS to 10.0.10.11:1812
  4. Test authentication: sudo systemctl status freeradius
  5. Monitor logs: tail -f /var/log/freeradius/radius.log

================================================================================
REPORT
}

main() {
	display_banner

	parse_args "$@"

	# Handle rollback mode
	if [[ -n "$ROLLBACK_DIR" ]]; then
		rollback
	fi

	# Pre-flight checks
	preflight

	# Create backup before changes
	create_backup

	# Run phases
	run_phases

	# Validate postconditions
	validate_postconditions

	# Generate report
	generate_report

	log success "DEPLOYMENT COMPLETE — Fortress Eternal"
	exit 0
}

# Execute main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
