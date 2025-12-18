#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/proxmox/phases/phase0-validate.sh
# Purpose: Orchestrator for pre-flight validation (Whitaker Red-Team)
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6
# Supports: flatnet recon, Cloud Key validation, LXC validation, red-team mode

# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)/lib/common.sh"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/metrics.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)/lib/metrics.sh"

# Parse arguments
MODE="full"
CLOUDKEY_IP=""
SKIP_UNIFI=false

while [[ $# -gt 0 ]]; do
	case $1 in
	--recon-only)
		MODE="recon-only"
		shift
		;;
	--skip-unifi)
		SKIP_UNIFI=true
		shift
		;;
	--validate-cloudkey)
		MODE="validate-cloudkey"
		shift
		;;
	--cloudkey-ip)
		CLOUDKEY_IP="$2"
		shift 2
		;;
	--validate-lxc)
		MODE="validate-lxc"
		shift
		;;
	--red-team-mode)
		MODE="red-team"
		shift
		;;
	*)
		log_warn "Unknown flag: $1"
		shift
		;;
	esac
done

# ============================================================================
# SOURCE MODULES
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/phase0-prerequisites.sh
source "${SCRIPT_DIR}/lib/phase0-prerequisites.sh"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/phase0-flatnet-recon.sh
source "${SCRIPT_DIR}/lib/phase0-flatnet-recon.sh"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/phase0-cloudkey.sh
source "${SCRIPT_DIR}/lib/phase0-cloudkey.sh"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/phase0-lxc.sh
source "${SCRIPT_DIR}/lib/phase0-lxc.sh"
# shellcheck source=/home/egx570/repos/rylan-unifi-case-study/01_bootstrap/proxmox/lib/phase0-red-team.sh
source "${SCRIPT_DIR}/lib/phase0-red-team.sh"

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
	case "$MODE" in
	recon-only)
		run_flatnet_recon
		;;
	validate-cloudkey)
		run_cloudkey_validation "$CLOUDKEY_IP"
		;;
	validate-lxc)
		run_lxc_validation
		;;
	red-team)
		run_red_team_audit "$SKIP_UNIFI" "$CLOUDKEY_IP"
		;;
	full)
		run_prerequisites_validation
		if [ "$SKIP_UNIFI" = false ]; then
			log_info "Skipping controller validation (use --validate-cloudkey or --validate-lxc post-setup)"
		fi
		;;
	*)
		log_error "Unknown mode: $MODE"
		exit 1
		;;
	esac
}

main
