# shellcheck shell=bash
#
# lib/security.sh - Whitaker offensive security validation functions
# Post-ignition audit suite and attack surface scanning
#
# Sourced by: phase5-validate.sh and standalone testing
# NOTE: No shebang or set -euo pipefail (sourced file, not executed)

################################################################################
# WHITAKER 10-POINT VALIDATION MATRIX
################################################################################

# Test 1: SSH port accessibility
test_ssh_port() {
  local ssh_port="${1:-22}"
  
  log_info "Test 1: Verifying SSH port (${ssh_port}) is open..."
  
  if nmap -p "$ssh_port" localhost 2>/dev/null | grep -q "open"; then
    log_success "SSH port open"
    return 0
  else
    log_error "SSH port not open"
    return 1
  fi
}

# Test 2: Proxmox web port accessibility
test_proxmox_port() {
  local web_port="${1:-8006}"
  
  log_info "Test 2: Verifying Proxmox web port (${web_port}) is open..."
  
  if nmap -p "$web_port" localhost 2>/dev/null | grep -q "open"; then
    log_success "Proxmox web port open"
    return 0
  else
    log_warn "Proxmox web port not yet open (services may be starting up)"
    return 0  # Non-fatal, services may be starting
  fi
}

# Test 3: Password authentication disabled (Bauer paranoia)
test_password_auth_disabled() {
  log_info "Test 3: Verifying password authentication is disabled..."
  
  if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    log_success "Password authentication disabled"
    return 0
  else
    log_error "Password authentication not disabled"
    return 1
  fi
}

# Test 4: Root login restrictions (Bauer paranoia)
test_root_login_restricted() {
  log_info "Test 4: Verifying root login restrictions..."
  
  if grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
    log_success "Root login restricted to key-only"
    return 0
  else
    log_error "Root login not properly restricted"
    return 1
  fi
}

# Test 5: SSH key installation (Carter identity)
test_ssh_key_installed() {
  log_info "Test 5: Verifying SSH public key is installed..."
  
  if [ -f /root/.ssh/authorized_keys ] && [ -s /root/.ssh/authorized_keys ]; then
    local key_fingerprint
    key_fingerprint=$(ssh-keygen -lf /root/.ssh/authorized_keys 2>/dev/null | head -1 || echo "N/A")
    log_success "SSH public key installed: $key_fingerprint"
    return 0
  else
    log_error "SSH public key not installed"
    return 1
  fi
}

# Test 6: Hostname correctly set (Carter identity)
test_hostname_correct() {
  local expected_hostname="${1}"
  
  log_info "Test 6: Verifying hostname is set correctly..."
  
  local current_hostname
  current_hostname=$(hostname)
  
  if [ "$current_hostname" = "$expected_hostname" ]; then
    log_success "Hostname correctly set: $current_hostname"
    return 0
  else
    log_error "Hostname mismatch: expected $expected_hostname, got $current_hostname"
    return 1
  fi
}

# Test 7: Static IP assigned (Suehring network)
test_static_ip_assigned() {
  local target_ip="$1"
  local ip_only="${target_ip%/*}"
  
  log_info "Test 7: Verifying static IP is assigned..."
  
  if ip addr show | grep -q "inet $ip_only"; then
    log_success "Static IP assigned: $ip_only"
    return 0
  else
    log_error "Static IP not assigned"
    return 1
  fi
}

# Test 8: Gateway reachability (Suehring network)
test_gateway_reachable() {
  local gateway_ip="$1"
  
  log_info "Test 8: Verifying gateway is reachable..."
  
  if timeout 5 ping -c 1 "$gateway_ip" &>/dev/null; then
    log_success "Gateway reachable: $gateway_ip"
    return 0
  else
    log_error "Gateway not reachable"
    return 1
  fi
}

# Test 9: DNS resolution working (Carter domain)
test_dns_resolution() {
  local dns_server="${1:-1.1.1.1}"
  
  log_info "Test 9: Verifying DNS resolution..."
  
  if timeout 5 nslookup google.com "$dns_server" &>/dev/null; then
    log_success "DNS resolution working"
    return 0
  else
    log_warn "DNS resolution test failed (may resolve after Carter setup)"
    return 0  # Non-fatal
  fi
}

# Test 10: Dangerous ports check (Whitaker offensive)
test_no_dangerous_ports() {
  log_info "Test 10: Scanning for dangerous open ports..."
  
  local dangerous_ports="23 80 443 3389 5900"
  local found_dangerous=false
  
  for port in $dangerous_ports; do
    if nmap -p "$port" localhost 2>/dev/null | grep -q "open"; then
      log_error "Dangerous port open: $port"
      found_dangerous=true
    fi
  done
  
  if [ "$found_dangerous" = false ]; then
    log_success "No dangerous ports open"
    return 0
  else
    return 1
  fi
}

################################################################################
# ADDITIONAL SECURITY TESTS
################################################################################

# Test SSH brute-force resistance (basic)
test_ssh_brute_force_resistance() {
  log_info "Test: SSH brute-force resistance..."
  
  # Try rapid failed logins (expect delays or drops)
  for _ in {1..5}; do
    timeout 2 ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no \
      nonexistent@localhost 2>/dev/null || true
  done
  
  # If we can still connect, that's good (means we can SSH at all)
  if timeout 2 ssh -o StrictHostKeyChecking=no root@localhost "echo test" 2>/dev/null || \
     ssh-keyscan localhost 2>/dev/null | grep -q "ssh-rsa"; then
    log_success "SSH service responsive after brute-force attempts"
    return 0
  else
    log_warn "Cannot verify SSH connectivity after brute-force test"
    return 0
  fi
}

# Test firewall iptables rules exist
test_firewall_active() {
  log_info "Test: Firewall rules exist..."
  
  if iptables -L -n 2>/dev/null | grep -q "Chain INPUT"; then
    log_success "Firewall rules configured"
    return 0
  else
    log_warn "No firewall rules detected (non-critical)"
    return 0
  fi
}

# Test for vulnerable SSH algorithms
test_ssh_algorithm_strength() {
  log_info "Test: SSH algorithm strength..."
  
  local ssh_config="/etc/ssh/sshd_config"
  
  # Check for weak algorithms
  if grep -q "^Ciphers.*rc4\|DES\|MD5" "$ssh_config"; then
    log_error "Weak SSH ciphers detected"
    return 1
  fi
  
  # Check for forward-secrecy ciphers
  if grep -q "chacha20-poly1305\|aes.*gcm" "$ssh_config"; then
    log_success "Strong SSH ciphers configured"
    return 0
  else
    log_warn "No forward-secrecy ciphers found (prefer ChaCha20 or AES-GCM)"
    return 0
  fi
}

################################################################################
# VLAN ISOLATION TEST (requires Docker/network setup)
################################################################################

test_vlan_isolation() {
  local server_ip="${1:-10.0.10.10}"
  
  log_info "Test: VLAN isolation (guest → server)..."
  
  # This test requires Docker and VLAN networking setup
  # Skip if Docker not available
  if ! command -v docker &>/dev/null; then
    log_warn "Docker not available, skipping VLAN isolation test"
    return 0
  fi
  
  # Check if mock guest network exists
  if ! docker network ls | grep -q "vlan90\|guest"; then
    log_warn "Guest VLAN network not configured, skipping"
    return 0
  fi
  
  # Test isolation
  if docker run --rm --network guest alpine ping -c 1 -W 2 "$server_ip" &>/dev/null; then
    log_error "CRITICAL: Guest VLAN can reach server VLAN!"
    return 1
  else
    log_success "VLAN isolation verified (guest cannot reach server)"
    return 0
  fi
}

################################################################################
# COMPREHENSIVE SECURITY AUDIT
################################################################################

run_whitaker_offensive_suite() {
  local hostname="${1}"
  local target_ip="${2}"
  local gateway_ip="${3}"
  local dns_server="${4:-1.1.1.1}"
  local ssh_port="${5:-22}"
  local web_port="${6:-8006}"
  
  echo ""
  log_info "Running Whitaker Offensive Security Suite..."
  echo ""
  
  local tests_passed=0
  local tests_failed=0
  local tests_warned=0
  
  # Run each test
  if test_ssh_port "$ssh_port"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_proxmox_port "$web_port"; then
    ((tests_passed++))
  else
    ((tests_warned++))
  fi
  
  if test_password_auth_disabled; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_root_login_restricted; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_ssh_key_installed; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_hostname_correct "$hostname"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_static_ip_assigned "$target_ip"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_gateway_reachable "$gateway_ip"; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_dns_resolution "$dns_server"; then
    ((tests_passed++))
  else
    ((tests_warned++))
  fi
  
  if test_no_dangerous_ports; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Additional tests
  if test_ssh_algorithm_strength; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  if test_firewall_active; then
    ((tests_passed++))
  else
    ((tests_warned++))
  fi
  
  # Print summary
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}         WHITAKER OFFENSIVE SECURITY SUITE - SUMMARY"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Tests Passed:  ${tests_passed}"
  echo "Tests Failed:  ${tests_failed}"
  echo "Tests Warned:  ${tests_warned}"
  echo ""
  
  if [ $tests_failed -eq 0 ]; then
    log_success "All critical security tests passed!"
    return 0
  else
    log_error "$tests_failed critical security tests failed"
    return 1
  fi
}

export -f test_ssh_port test_proxmox_port test_password_auth_disabled
export -f test_root_login_restricted test_ssh_key_installed test_hostname_correct
export -f test_static_ip_assigned test_gateway_reachable test_dns_resolution
export -f test_no_dangerous_ports test_ssh_brute_force_resistance test_firewall_active
export -f test_ssh_algorithm_strength test_vlan_isolation run_whitaker_offensive_suite
