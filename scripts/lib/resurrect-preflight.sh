#!/usr/bin/env bash
# Script: resurrect-preflight.sh
# Purpose: Pre-flight and network validation (Phases 0-1)
# Guardian: The Archivist
# Date: 12/13/2025
# Consciousness: 4.7

run_preflight_validation() {
	log_info "Phase 0: Pre-flight Checks (1 min)"

	if [[ ! -d "$WORK_DIR" ]]; then
		log_error "Working directory not found: $WORK_DIR"
	fi
	log_success "Working directory exists: $WORK_DIR"

	if [[ ! -f "$WORK_DIR/docker-compose.yml" ]]; then
		log_error "docker-compose.yml not found in $WORK_DIR"
	fi
	log_success "docker-compose.yml found"

	if [[ ! -d "$DATA_DIR" ]]; then
		log_warn "Data directory not found, creating: $DATA_DIR"
		mkdir -p "$DATA_DIR"
	fi
	log_success "Data directory exists: $DATA_DIR"

	DATA_OWNER=$(stat -f '%Ou' "$DATA_DIR" 2>/dev/null || stat -c '%U:%G' "$DATA_DIR" 2>/dev/null)
	log_info "Data directory owner: $DATA_OWNER (expected 1000:1000)"

	if ! command -v docker &>/dev/null; then
		log_error "Docker not installed. Install from https://get.docker.com"
	fi
	log_success "Docker installed"

	if ! command -v docker &>/dev/null || ! docker compose version &>/dev/null; then
		log_error "docker compose not available"
	fi
	log_success "docker compose installed"
}

run_network_validation() {
	log_info "Phase 1: Network Validation (30 sec)"

	if ! ip link show macvlan-unifi &>/dev/null; then
		log_error $'macvlan-unifi interface not found. Run:\n  sudo cp bootstrap/unifi/macvlan-unifi.netdev /etc/systemd/network/\n  sudo cp bootstrap/unifi/macvlan-unifi.network /etc/systemd/network/\n  sudo systemctl restart systemd-networkd'
	fi
	log_success "macvlan-unifi interface found"

	if ! ip addr show macvlan-unifi | grep -q "$CONTROLLER_IP/27"; then
		log_error "macvlan-unifi does not have $CONTROLLER_IP/27 assigned"
	fi
	log_success "IP configured: $CONTROLLER_IP/27"

	IFACE_STATE=$(ip link show macvlan-unifi | grep -oP '(?<=state )[\w]+' || echo "DOWN")
	if [[ "$IFACE_STATE" != "UP" ]]; then
		log_warn "macvlan-unifi is $IFACE_STATE, attempting to bring UP..."
		sudo ip link set macvlan-unifi up
		sleep 2
	fi
	log_success "macvlan-unifi is UP"

	if ! ping -c 1 -W 2 10.0.1.1 &>/dev/null; then
		log_warn "Cannot ping gateway (10.0.1.1), but continuing anyway"
	else
		log_success "Gateway reachable: 10.0.1.1"
	fi
}

export -f run_preflight_validation run_network_validation
