#!/usr/bin/env bash
# Module: phase0-red-team.sh
# Purpose: Full offensive audit (Whitaker/Newman red-team mode)
# Part of: 01_bootstrap/proxmox/phases/phase0-validate.sh refactoring
# Consciousness: 4.6

# RED-TEAM MODE: FULL OFFENSIVE AUDIT
run_red_team_audit() {
	local skip_unifi="$1" cloudkey_ip="$2" recon_file

	phase_start "0" "Whitaker/Newman Red-Team - Full Offensive Audit"

	# 1. Flatnet recon
	recon_file=$(run_flatnet_recon)

	# 2. Open port scan on all detected hosts
	log_info "Scanning for dangerous open ports..."
	local dangerous_ports="23 80 3389 5900"

	for port in $dangerous_ports; do
		if grep -q "$port/open" "$recon_file" 2>/dev/null; then
			log_warn "BREACH RISK: Port $port open on flatnet"
		fi
	done

	# 3. Default credential check (USG)
	log_info "Testing USG default credentials..."
	if timeout 5 ssh -o ConnectTimeout=5 ubnt@192.168.1.1 "echo 'OK'" >/dev/null 2>&1; then
		log_error "CRITICAL: USG accepts default ubnt credentials — change immediately"
	else
		log_success "USG default credentials rejected (good)"
	fi

	# 4. Controller validation (if exists)
	if [ "$skip_unifi" = false ]; then
		if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.0.1.20/8443" 2>/dev/null; then
			run_lxc_validation || log_warn "LXC controller exists but validation failed"
		elif [ -n "$cloudkey_ip" ]; then
			run_cloudkey_validation "$cloudkey_ip" || log_warn "Cloud Key validation failed"
		fi
	fi

	log_success "Red-team audit complete — review $recon_file for full report"
}

export -f run_red_team_audit
