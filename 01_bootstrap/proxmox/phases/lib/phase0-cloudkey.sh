#!/usr/bin/env bash
# Module: phase0-cloudkey.sh
# Purpose: Cloud Key adoption and API validation
# Part of: 01_bootstrap/proxmox/phases/phase0-validate.sh refactoring
# Consciousness: 4.6

# CLOUD KEY VALIDATION
run_cloudkey_validation() {
  local cloudkey_ip="$1"

  if [ -z "$cloudkey_ip" ]; then
    log_error "Cloud Key IP required for validation"
    return 1
  fi

  phase_start "0" "Cloud Key Validation - $cloudkey_ip"

  # Test 1: Port 443 reachable
  log_info "Testing Cloud Key connectivity (443/tcp)..."
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$cloudkey_ip/443" 2>/dev/null; then
    log_success "Cloud Key reachable on 443/tcp"
  else
    log_error "Cloud Key not reachable at $cloudkey_ip:443"
    return 1
  fi

  # Test 2: HTTPS API responsive
  log_info "Testing Cloud Key API..."
  if timeout 5 curl -k -s "https://$cloudkey_ip:443/api/v2/system/info" >/dev/null 2>&1; then
    log_success "Cloud Key API is responsive"
  else
    log_warn "Cloud Key API not responding (may still be booting)"
  fi

  # Test 3: SSH access
  log_info "Testing SSH access (ubnt user)..."
  if timeout 5 ssh -o ConnectTimeout=5 "ubnt@$cloudkey_ip" "echo 'OK'" >/dev/null 2>&1; then
    log_success "SSH access working"
  else
    log_warn "SSH access failed (check ubnt user setup)"
  fi

  log_success "Cloud Key validation complete"
}

export -f run_cloudkey_validation
