#!/bin/bash
#
# test-ignite-security.sh - Whitaker 10-Point Offensive Security Suite
# Purpose: Attack the post-ignition fortress to validate hardening
# Status: Production-ready, integrated with CI/CD
# Author: Proxmox-Ignite v2 (post-deployment security validation)
#

set -euo pipefail

# ============================================================================
# CONFIGURATION & GLOBALS
# ============================================================================

SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
# shellcheck disable=SC2034
export REPO_ROOT

readonly TEST_REPORT="/tmp/ignite-security-report.json"

# Test status tracking
CRITICAL_FAILURES=0
HIGH_WARNINGS=0
INFO_ONLY=0

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# LOGGING & REPORTING
# ============================================================================

log_test_start() {
  local test_num=$1
  local test_name=$2
  local severity=$3
  printf "[%02d] %-40s [%s]" "$test_num" "$test_name" "$severity"
}

log_result() {
  local result=$1
  case "$result" in
    PASS)
      echo -e " ${GREEN}PASS${NC}"
      ;;
    FAIL)
      echo -e " ${RED}FAIL${NC}"
      ((CRITICAL_FAILURES++))
      ;;
    WARN)
      echo -e " ${YELLOW}WARN${NC}"
      ((HIGH_WARNINGS++))
      ;;
    INFO)
      echo -e " ${BLUE}INFO${NC}"
      ((INFO_ONLY++))
      ;;
    *)
      echo " UNKNOWN"
      ;;
  esac
}

add_finding() {
  local severity=$1
  local title=$2
  local detail=$3
  echo "{\"severity\": \"$severity\", \"title\": \"$title\", \"detail\": \"$detail\"}," >> "$TEST_REPORT"
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_prerequisites() {
  echo "Checking prerequisites..."
  
  local missing_tools=()
  
  # Check required commands
  for cmd in sshpass nmap netstat grep awk sed; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_tools+=("$cmd")
    fi
  done
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo "${RED}ERROR: Missing required tools: ${missing_tools[*]}${NC}"
    echo "Install with: sudo apt-get install -y sshpass nmap net-tools"
    return 1
  fi
  
  echo "${GREEN}✓ All prerequisite tools available${NC}"
  return 0
}

get_target_ip() {
  # Try to detect target from arguments or environment
  if [[ -n "${TARGET_IP:-}" ]]; then
    echo "$TARGET_IP"
    return 0
  fi
  
  # Default to localhost (for CI testing)
  echo "localhost"
}

# ============================================================================
# WHITAKER 10-POINT OFFENSIVE TESTS
# ============================================================================

# Test 1: SSH PASSWORD AUTH (should be DISABLED)
test_ssh_password_auth() {
  log_test_start 1 "SSH Password Authentication Disabled" "CRITICAL"
  
  local target="${1:-localhost}"
  local test_user="${2:-root}"
  
  # Try to login with a dummy password (should fail)
  if sshpass -p "dummypassword123" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PasswordAuthentication=yes \
    "$test_user@$target" "whoami" &>/dev/null 2>&1; then
    
    log_result "FAIL"
    add_finding "CRITICAL" "Password auth enabled" "SSH allows password-based login (should be key-only)"
    return 1
  fi
  
  # Check SSH config explicitly
  if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
    log_result "FAIL"
    add_finding "CRITICAL" "PasswordAuthentication yes" "Config allows passwords"
    return 1
  fi
  
  log_result "PASS"
  return 0
}

# Test 2: SSH KEY FORMAT (only ed25519 or modern algorithms)
test_ssh_key_format() {
  log_test_start 2 "SSH Key Algorithm Strength" "MEDIUM"
  
  local auth_keys_file="${HOME}/.ssh/authorized_keys"
  
  if [[ ! -f "$auth_keys_file" ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "No authorized_keys found" "Cannot validate key format"
    return 1
  fi
  
  local weak_keys=0
  local strong_keys=0
  
  while IFS= read -r line; do
    [[ "$line" =~ ^#.* ]] && continue
    [[ -z "$line" ]] && continue
    
    if [[ "$line" =~ ssh-ed25519 ]] || [[ "$line" =~ ecdsa-sha2 ]]; then
      ((strong_keys++))
    elif [[ "$line" =~ ssh-rsa ]]; then
      ((weak_keys++))
    fi
  done < "$auth_keys_file"
  
  if [[ $weak_keys -gt 0 ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "Weak RSA keys found" "$weak_keys RSA keys (should use ed25519)"
    return 1
  fi
  
  if [[ $strong_keys -eq 0 ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "No strong keys found" "authorized_keys empty or invalid"
    return 1
  fi
  
  log_result "PASS"
  return 0
}

# Test 3: OPEN PORT SCAN (only SSH 22 and Proxmox 8006 allowed)
test_open_ports() {
  log_test_start 3 "Open Port Restrictions" "CRITICAL"
  
  local target="${1:-localhost}"
  local allowed_ports=(22 8006)
  local unexpected_ports=()
  
  # Use netstat to find listening ports locally
  if [[ "$target" == "localhost" ]] || [[ "$target" == "127.0.0.1" ]]; then
    local listen_ports
    listen_ports=$(netstat -tuln 2>/dev/null | grep LISTEN | awk '{print $4}' | awk -F: '{print $NF}' | sort -u)
    
    while read -r port; do
      [[ -z "$port" ]] && continue
      
      # Check if port is in allowed list
      local is_allowed=0
      for allowed_port in "${allowed_ports[@]}"; do
        if [[ "$port" -eq "$allowed_port" ]]; then
          is_allowed=1
          break
        fi
      done
      
      if [[ $is_allowed -eq 0 ]] && [[ "$port" -gt 1024 ]]; then
        unexpected_ports+=("$port")
      fi
    done <<< "$listen_ports"
    
    if [[ ${#unexpected_ports[@]} -gt 0 ]]; then
      log_result "WARN"
      add_finding "HIGH" "Unexpected open ports" "Ports ${unexpected_ports[*]} listening"
      return 1
    fi
  else
    # Use nmap for remote scanning
    local nmap_result
    nmap_result=$(nmap -p- "$target" 2>/dev/null | grep "open" | awk '{print $1}' | cut -d'/' -f1 || true)
    
    while read -r port; do
      [[ -z "$port" ]] && continue
      
      local is_allowed=0
      for allowed_port in "${allowed_ports[@]}"; do
        if [[ "$port" -eq "$allowed_port" ]]; then
          is_allowed=1
          break
        fi
      done
      
      if [[ $is_allowed -eq 0 ]]; then
        unexpected_ports+=("$port")
      fi
    done <<< "$nmap_result"
    
    if [[ ${#unexpected_ports[@]} -gt 0 ]]; then
      log_result "FAIL"
      add_finding "CRITICAL" "Unexpected ports open" "Ports ${unexpected_ports[*]} exposed"
      return 1
    fi
  fi
  
  log_result "PASS"
  return 0
}

# Test 4: ROOT LOGIN RESTRICTION (prohibit-password or no)
test_root_login() {
  log_test_start 4 "Root SSH Login Restrictions" "HIGH"
  
  local sshd_config="/etc/ssh/sshd_config"
  
  if [[ ! -f "$sshd_config" ]]; then
    log_result "WARN"
    add_finding "HIGH" "sshd_config not found" "Cannot verify root login policy"
    return 1
  fi
  
  # Check PermitRootLogin setting
  local permit_root
  permit_root=$(grep "^PermitRootLogin" "$sshd_config" | awk '{print $2}' || echo "")
  
  case "$permit_root" in
    "no"|"prohibit-password"|"without-password")
      log_result "PASS"
      return 0
      ;;
    "yes")
      log_result "FAIL"
      add_finding "CRITICAL" "PermitRootLogin yes" "Root login enabled"
      return 1
      ;;
    *)
      log_result "WARN"
      add_finding "HIGH" "PermitRootLogin unknown" "Setting: $permit_root"
      return 1
      ;;
  esac
}

# Test 5: FIREWALL STATUS (iptables rules configured)
test_firewall_active() {
  log_test_start 5 "Firewall Rules Configured" "MEDIUM"
  
  local iptables_rules
  iptables_rules=$(iptables -L -n 2>/dev/null | grep -c "Chain INPUT" || echo "0")
  
  if [[ "$iptables_rules" -eq 0 ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "No iptables rules found" "Firewall may not be configured"
    return 1
  fi
  
  # Check for DROP/REJECT default policies
  local input_policy
  input_policy=$(iptables -L INPUT -n 2>/dev/null | grep "Chain INPUT" | awk '{print $4}' || echo "")
  
  if [[ ! "$input_policy" =~ (DROP|REJECT) ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "INPUT policy not DROP/REJECT" "Policy: $input_policy"
    return 1
  fi
  
  log_result "PASS"
  return 0
}

# Test 6: SSH BRUTE-FORCE RESISTANCE (rate limiting or fail2ban)
test_ssh_brute_force() {
  log_test_start 6 "SSH Brute-Force Resistance" "HIGH"
  
  local sshd_config="/etc/ssh/sshd_config"
  
  # Check for rate limiting or fail2ban
  if grep -q "^MaxAuthTries\|^MaxSessions" "$sshd_config" 2>/dev/null; then
    local max_auth
    max_auth=$(grep "^MaxAuthTries" "$sshd_config" | awk '{print $2}')
    
    if [[ -n "$max_auth" ]] && [[ "$max_auth" -le 3 ]]; then
      log_result "PASS"
      return 0
    fi
  fi
  
  # Check for fail2ban
  if systemctl is-active fail2ban &>/dev/null 2>&1; then
    log_result "PASS"
    add_finding "INFO" "fail2ban active" "Brute-force protection via fail2ban"
    return 0
  fi
  
  log_result "WARN"
  add_finding "HIGH" "No brute-force protection detected" "Consider fail2ban or tighter MaxAuthTries"
  return 1
}

# Test 7: HOSTNAME CORRECT (matches config)
test_hostname() {
  log_test_start 7 "Hostname Validation" "LOW"
  
  local hostname
  hostname=$(hostname)
  
  # Check if hostname matches expected pattern (should not be default)
  if [[ "$hostname" =~ (localhost|ubuntu|debian|proxmox-default) ]]; then
    log_result "WARN"
    add_finding "LOW" "Default hostname detected" "Hostname: $hostname"
    return 1
  fi
  
  log_result "PASS"
  return 0
}

# Test 8: STATIC IP ASSIGNED (not DHCP)
test_static_ip() {
  log_test_start 8 "Static IP Configuration" "MEDIUM"
  
  local netplan_dir="/etc/netplan"
  
  if [[ ! -d "$netplan_dir" ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "Netplan not configured" "Cannot verify IP configuration"
    return 1
  fi
  
  # Check for DHCP in netplan configs
  if grep -r "dhcp4: true" "$netplan_dir" 2>/dev/null | grep -qv "^\s*#"; then
    log_result "WARN"
    add_finding "MEDIUM" "DHCP enabled" "Should use static IP for servers"
    return 1
  fi
  
  log_result "PASS"
  return 0
}

# Test 9: GATEWAY REACHABLE (network connectivity)
test_gateway() {
  log_test_start 9 "Gateway Reachability" "MEDIUM"
  
  local gateway
  gateway=$(ip route | grep default | awk '{print $3}' | head -1)
  
  if [[ -z "$gateway" ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "No default gateway found" "Network may not be configured"
    return 1
  fi
  
  if ping -c 1 -W 2 "$gateway" &>/dev/null; then
    log_result "PASS"
    return 0
  else
    log_result "WARN"
    add_finding "MEDIUM" "Gateway unreachable" "Gateway: $gateway"
    return 1
  fi
}

# Test 10: DNS RESOLUTION (external)
test_dns() {
  log_test_start 10 "DNS Resolution" "LOW"
  
  # Try to resolve a reliable public domain
  if nslookup google.com 2>/dev/null | grep -q "Name:"; then
    log_result "PASS"
    return 0
  fi
  
  log_result "WARN"
  add_finding "LOW" "DNS resolution failed" "Cannot resolve external names"
  return 1
}

# ============================================================================
# ADDITIONAL SECURITY CHECKS (Bonus Whitaker Extensions)
# ============================================================================

# Test 11: VLAN ISOLATION (guest cannot reach mgmt network)
test_vlan_isolation() {
  log_test_start 11 "VLAN Isolation (Bonus)" "MEDIUM"
  
  # This requires network setup to test properly
  # For CI, we'll check for VLAN configuration existence
  
  if ip link show | grep -q "\."; then
    log_result "INFO"
    add_finding "INFO" "VLAN subinterfaces detected" "VLAN configured"
    return 0
  fi
  
  log_result "INFO"
  add_finding "INFO" "No VLAN subinterfaces found" "Single flat network"
  return 0
}

# Test 12: SERVICE ISOLATION (minimal privilege)
test_service_isolation() {
  log_test_start 12 "Service Privilege Isolation" "MEDIUM"
  
  # Count services running as root (should be minimal)
  local root_services
  root_services=$(pgrep -c -U root 2>/dev/null || echo 0)
  
  # Rough heuristic: >20 root processes might indicate over-privileging
  if [[ $root_services -gt 25 ]]; then
    log_result "WARN"
    add_finding "MEDIUM" "Many root services running" "Count: $root_services"
    return 1
  fi
  
  log_result "PASS"
  return 0
}

# ============================================================================
# MAIN ORCHESTRATOR
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "  Whitaker 10-Point Offensive Test Suite"
  echo "=========================================="
  echo ""
  
  # Check prerequisites
  if ! check_prerequisites; then
    exit 1
  fi
  
  # Initialize report
  true > "$TEST_REPORT"
  
  local target
  target=$(get_target_ip)
  echo "Target system: $target"
  echo ""
  echo "Running 12 security tests..."
  echo "=========================================="
  echo ""
  
  # Run all tests (continue on failure for comprehensive reporting)
  test_ssh_password_auth "$target" root || true
  test_ssh_key_format || true
  test_open_ports "$target" || true
  test_root_login || true
  test_firewall_active || true
  test_ssh_brute_force || true
  test_hostname || true
  test_static_ip || true
  test_gateway || true
  test_dns || true
  test_vlan_isolation || true
  test_service_isolation || true
  
  echo ""
  echo "=========================================="
  echo "  Test Results Summary"
  echo "=========================================="
  echo ""
  echo -e "  ${GREEN}✓ Tests Passed${NC}"
  echo "  ${YELLOW}⚠ Warnings${NC}: $HIGH_WARNINGS"
  echo "  ${RED}✗ Critical Failures${NC}: $CRITICAL_FAILURES"
  echo "  ${BLUE}ℹ Info Only${NC}: $INFO_ONLY"
  echo ""
  
  # Determine exit code
  if [[ $CRITICAL_FAILURES -gt 0 ]]; then
    echo -e "${RED}VERDICT: FORTRESS BREACHED (Critical failures detected)${NC}"
    echo ""
    return 1
  elif [[ $HIGH_WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}VERDICT: HARDENED but WITH WARNINGS${NC}"
    echo ""
    return 2
  else
    echo -e "${GREEN}VERDICT: FORTRESS HOLDS! All tests passed.${NC}"
    echo ""
    return 0
  fi
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  exit $?
fi
