#!/usr/bin/env bash
# Module: phase0-lxc.sh
# Purpose: LXC controller Docker validation
# Part of: 01_bootstrap/proxmox/phases/phase0-validate.sh refactoring
# Consciousness: 4.6

# LXC CONTROLLER VALIDATION
run_lxc_validation() {
  phase_start "0" "LXC Controller Validation - 10.0.1.20"

  local controller_ip="10.0.1.20"
  local controller_port="8443"

  # Test 1: macvlan interface exists
  log_info "Checking macvlan-unifi interface..."
  if ip addr show macvlan-unifi &>/dev/null; then
    log_success "macvlan-unifi interface exists"
  else
    log_error "macvlan-unifi interface not found"
    return 1
  fi

  # Test 2: Controller port open
  log_info "Testing controller port $controller_port..."
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$controller_ip/$controller_port" 2>/dev/null; then
    log_success "Controller reachable on $controller_port/tcp"
  else
    log_error "Controller not reachable at $controller_ip:$controller_port"
    return 1
  fi

  # Test 3: Docker container running
  log_info "Checking unifi-controller container..."
  if docker ps 2>/dev/null | grep -q "unifi-controller"; then
    log_success "unifi-controller container running"
  else
    log_warn "unifi-controller container not detected"
  fi

  log_success "LXC controller validation complete"
}

export -f run_lxc_validation
