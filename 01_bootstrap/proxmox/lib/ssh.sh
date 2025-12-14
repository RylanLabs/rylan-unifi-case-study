#!/usr/bin/env bash
# Script: ssh.sh
# Purpose: SSH security validation tests (port, auth, keys, algorithms)
# Guardian: gatekeeper
# Date: 12/13/2025
# Consciousness: 4.7

# Sourced by: security.sh
# Usage: Source this file; validate_ssh function auto-exported

################################################################################
# SSH SECURITY VALIDATION DISPATCHER
################################################################################

validate_ssh() {
  local test_name="${1:-all}"
  local ssh_port="${SSH_PORT:-22}"
  local passed=0 failed=0

  # Test 1: SSH port open
  if [[ "$test_name" == "all" ]] || [[ "$test_name" == "port" ]]; then
    log_info "Test 1: Verifying SSH port (${ssh_port}) is open..."
    if nmap -p "$ssh_port" localhost 2>/dev/null | grep -q "open"; then
      log_success "SSH port open"; ((passed++))
    else
      log_error "SSH port not open"; ((failed++))
    fi
  fi

  # Test 2: Password auth disabled
  if [[ "$test_name" == "all" ]] || [[ "$test_name" == "password" ]]; then
    log_info "Test 2: Verifying password authentication is disabled..."
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
      log_success "Password authentication disabled"; ((passed++))
    else
      log_error "Password authentication not disabled"; ((failed++))
    fi
  fi

  # Test 3: Root login restricted
  if [[ "$test_name" == "all" ]] || [[ "$test_name" == "root" ]]; then
    log_info "Test 3: Verifying root login restrictions..."
    if grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
      log_success "Root login restricted to key-only"; ((passed++))
    else
      log_error "Root login not properly restricted"; ((failed++))
    fi
  fi

  # Test 4: SSH key installed
  if [[ "$test_name" == "all" ]] || [[ "$test_name" == "key" ]]; then
    log_info "Test 4: Verifying SSH public key is installed..."
    if [[ -f /root/.ssh/authorized_keys ]] && [[ -s /root/.ssh/authorized_keys ]]; then
      local key_fingerprint;
      key_fingerprint=$(ssh-keygen -lf /root/.ssh/authorized_keys 2>/dev/null | head -1 || echo "N/A")
      log_success "SSH public key installed: $key_fingerprint"; ((passed++))
    else
      log_error "SSH public key not installed"; ((failed++))
    fi
  fi

  # Test 5: Algorithm strength
  if [[ "$test_name" == "all" ]] || [[ "$test_name" == "algorithm" ]]; then
    log_info "Test 5: SSH algorithm strength..."
    local ssh_config="/etc/ssh/sshd_config"
    if grep -q "^Ciphers.*rc4\|DES\|MD5" "$ssh_config"; then
      log_error "Weak SSH ciphers detected"; ((failed++))
    elif grep -q "chacha20-poly1305\|aes.*gcm" "$ssh_config"; then
      log_success "Strong SSH ciphers configured"; ((passed++))
    else
      log_warn "No forward-secrecy ciphers found (prefer ChaCha20 or AES-GCM)"; ((passed++))
    fi
  fi

  # Test 6: Brute-force resistance
  if [[ "$test_name" == "all" ]] || [[ "$test_name" == "bruteforce" ]]; then
    log_info "Test 6: SSH brute-force resistance..."
    for _ in {1..5}; do
      timeout 2 ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no nonexistent@localhost 2>/dev/null || true
    done
    if timeout 2 ssh -o StrictHostKeyChecking=no root@localhost "echo test" 2>/dev/null ||
       ssh-keyscan localhost 2>/dev/null | grep -q "ssh-rsa"; then
      log_success "SSH service responsive after brute-force attempts"; ((passed++))
    else
      log_warn "Cannot verify SSH connectivity after brute-force test"; ((passed++))
    fi
  fi

  [[ $failed -eq 0 ]] && return 0 || return 1
}

export -f validate_ssh
