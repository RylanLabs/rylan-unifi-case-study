#!/usr/bin/env bash
#
# Proxmox Ignite Validation Test Suite
# Smoke tests for proxmox-ignite.sh deployment
#
# Usage:
#   sudo bash tests/proxmox/test-proxmox-ignite.sh
#
# This suite validates:
# - Script syntax and structure
# - Argument parsing and validation
# - Network configuration logic
# - SSH hardening settings
# - Security validation checks
#
# Exit codes:
#   0: All tests passed
#   1: One or more tests failed

set -euo pipefail

################################################################################
# TEST FRAMEWORK SETUP
################################################################################

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${TEST_DIR}")/.." && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/01-bootstrap/proxmox/proxmox-ignite.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# TEST UTILITIES
################################################################################

# Test result logger
test_case() {
  local test_name="$1"
  echo -e "${BLUE}→${NC} $test_name"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

test_pass() {
  local message="$1"
  echo -e "  ${GREEN}✅ PASS${NC}: $message"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  local message="$1"
  echo -e "  ${RED}❌ FAIL${NC}: $message"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_warn() {
  local message="$1"
  echo -e "  ${YELLOW}⚠️  WARN${NC}: $message"
}

# Test assertion helpers
assert_file_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    test_pass "File exists: $file"
  else
    test_fail "File not found: $file"
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  if [ ! -f "$file" ]; then
    test_fail "File not found: $file"
    return 1
  fi

  if grep -q "$pattern" "$file"; then
    test_pass "Pattern found in $file: $pattern"
  else
    test_fail "Pattern not found in $file: $pattern"
    return 1
  fi
}

assert_executable() {
  local file="$1"
  if [ -x "$file" ]; then
    test_pass "File is executable: $file"
  else
    test_fail "File is not executable: $file"
    return 1
  fi
}

################################################################################
# SUITE 1: SCRIPT EXISTENCE & PERMISSIONS
################################################################################

suite_script_integrity() {
  echo -e "\n${BLUE}TEST SUITE 1: Script Integrity${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Proxmox ignition script exists"
  assert_file_exists "$SCRIPT_PATH"

  test_case "Script is executable"
  assert_executable "$SCRIPT_PATH"

  test_case "Script has shebang"
  assert_file_contains "$SCRIPT_PATH" "^#!/usr/bin/env bash"

  test_case "Script has error handling (set -euo pipefail)"
  assert_file_contains "$SCRIPT_PATH" "^set -euo pipefail"

  test_case "README documentation exists"
  assert_file_exists "${SCRIPT_DIR}/01-bootstrap/proxmox/README.md"

  test_case "Preseed configuration exists"
  assert_file_exists "${SCRIPT_DIR}/01-bootstrap/proxmox/proxmox-answer.cfg"
}

################################################################################
# SUITE 2: SCRIPT STRUCTURE VALIDATION
################################################################################

suite_script_structure() {
  echo -e "\n${BLUE}TEST SUITE 2: Script Structure${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script contains configuration section"
  assert_file_contains "$SCRIPT_PATH" "^SCRIPT_START="

  test_case "Script contains phase 0 (validation)"
  assert_file_contains "$SCRIPT_PATH" "^validate_prerequisites()"

  test_case "Script contains phase 1 (network)"
  assert_file_contains "$SCRIPT_PATH" "^configure_network()"

  test_case "Script contains phase 2 (SSH hardening)"
  assert_file_contains "$SCRIPT_PATH" "^harden_ssh()"

  test_case "Script contains phase 3 (tooling)"
  assert_file_contains "$SCRIPT_PATH" "^bootstrap_tooling()"

  test_case "Script contains phase 4 (repository)"
  assert_file_contains "$SCRIPT_PATH" "^sync_repository()"

  test_case "Script contains phase 5 (resurrection)"
  assert_file_contains "$SCRIPT_PATH" "^resurrect_fortress()"

  test_case "Script contains phase 6 (security validation)"
  assert_file_contains "$SCRIPT_PATH" "^validate_security()"

  test_case "Script has main entry point"
  assert_file_contains "$SCRIPT_PATH" "^main() {"

  test_case "Script calls main function"
  assert_file_contains "$SCRIPT_PATH" "^main \"\$@\""

  test_case "Script has argument parser"
  assert_file_contains "$SCRIPT_PATH" "^parse_arguments()"

  test_case "Script has help text"
  assert_file_contains "$SCRIPT_PATH" "^print_usage()"
}

################################################################################
# SUITE 3: ARGUMENT VALIDATION
################################################################################

suite_argument_validation() {
  echo -e "\n${BLUE}TEST SUITE 3: Argument Validation${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script validates hostname argument"
  assert_file_contains "$SCRIPT_PATH" "HOSTNAME.*=\"\$2\""

  test_case "Script validates IP/CIDR argument"
  assert_file_contains "$SCRIPT_PATH" "TARGET_IP.*=\"\$2\""

  test_case "Script validates gateway argument"
  assert_file_contains "$SCRIPT_PATH" "GATEWAY_IP.*=\"\$2\""

  test_case "Script validates SSH key argument"
  assert_file_contains "$SCRIPT_PATH" "SSH_KEY_PATH.*=\"\$2\""

  test_case "Script checks for required arguments"
  assert_file_contains "$SCRIPT_PATH" "if \[ -z \"\$HOSTNAME\" \]"

  test_case "Script validates hostname format"
  assert_file_contains "$SCRIPT_PATH" "\[a-zA-Z0-9\]\(\[a-zA-Z0-9-\]"

  test_case "Script validates IP/CIDR format"
  assert_file_contains "$SCRIPT_PATH" "\[0-9\]{1,3}\.\[0-9\]{1,3}\.\[0-9\]{1,3}\.\[0-9\]{1,3}/\[0-9\]{1,2}"
}

################################################################################
# SUITE 4: SSH HARDENING CONFIGURATION
################################################################################

suite_ssh_hardening() {
  echo -e "\n${BLUE}TEST SUITE 4: SSH Hardening Configuration${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script disables password authentication"
  assert_file_contains "$SCRIPT_PATH" "PasswordAuthentication no"

  test_case "Script restricts root login to key-only"
  assert_file_contains "$SCRIPT_PATH" "PermitRootLogin prohibit-password"

  test_case "Script enables public key authentication"
  assert_file_contains "$SCRIPT_PATH" "PubkeyAuthentication yes"

  test_case "Script disables empty passwords"
  assert_file_contains "$SCRIPT_PATH" "PermitEmptyPasswords no"

  test_case "Script disables X11 forwarding"
  assert_file_contains "$SCRIPT_PATH" "X11Forwarding no"

  test_case "Script configures strong ciphers"
  assert_file_contains "$SCRIPT_PATH" "chacha20-poly1305"

  test_case "Script configures strong KEX algorithms"
  assert_file_contains "$SCRIPT_PATH" "curve25519-sha256"
}

################################################################################
# SUITE 5: NETWORK CONFIGURATION
################################################################################

suite_network_configuration() {
  echo -e "\n${BLUE}TEST SUITE 5: Network Configuration${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script configures static IP"
  assert_file_contains "$SCRIPT_PATH" "address"

  test_case "Script sets netmask"
  assert_file_contains "$SCRIPT_PATH" "netmask"

  test_case "Script configures gateway"
  assert_file_contains "$SCRIPT_PATH" "gateway"

  test_case "Script configures DNS servers"
  assert_file_contains "$SCRIPT_PATH" "dns-nameservers"

  test_case "Script detects primary NIC"
  assert_file_contains "$SCRIPT_PATH" "en\[op\]\|eth"

  test_case "Script validates gateway reachability"
  assert_file_contains "$SCRIPT_PATH" "ping.*GATEWAY_IP"
}

################################################################################
# SUITE 6: SECURITY VALIDATION
################################################################################

suite_security_validation() {
  echo -e "\n${BLUE}TEST SUITE 6: Security Validation${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script validates SSH port"
  assert_file_contains "$SCRIPT_PATH" "nmap -p.*SSH_PORT"

  test_case "Script checks for password auth disabled"
  assert_file_contains "$SCRIPT_PATH" "PasswordAuthentication no"

  test_case "Script checks for root login restrictions"
  assert_file_contains "$SCRIPT_PATH" "PermitRootLogin prohibit-password"

  test_case "Script validates SSH key installation"
  assert_file_contains "$SCRIPT_PATH" "/root/.ssh/authorized_keys"

  test_case "Script validates hostname configuration"
  assert_file_contains "$SCRIPT_PATH" "hostname"

  test_case "Script validates static IP assignment"
  assert_file_contains "$SCRIPT_PATH" "ip addr show"

  test_case "Script scans for dangerous ports"
  assert_file_contains "$SCRIPT_PATH" "23 80 443"
}

################################################################################
# SUITE 7: ERROR HANDLING & LOGGING
################################################################################

suite_error_handling() {
  echo -e "\n${BLUE}TEST SUITE 7: Error Handling & Logging${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script defines logging function"
  assert_file_contains "$SCRIPT_PATH" "^log()"

  test_case "Script defines error function"
  assert_file_contains "$SCRIPT_PATH" "^error()"

  test_case "Script defines warning function"
  assert_file_contains "$SCRIPT_PATH" "^warning()"

  test_case "Script defines retry function"
  assert_file_contains "$SCRIPT_PATH" "^retry_command()"

  test_case "Script has log file configuration"
  assert_file_contains "$SCRIPT_PATH" "LOG_FILE="

  test_case "Script initializes log file"
  assert_file_contains "$SCRIPT_PATH" "touch.*LOG_FILE"

  test_case "Script has phase start indicators"
  assert_file_contains "$SCRIPT_PATH" "^phase_start()"
}

################################################################################
# SUITE 8: DOCUMENTATION QUALITY
################################################################################

suite_documentation() {
  echo -e "\n${BLUE}TEST SUITE 8: Documentation Quality${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local readme="${SCRIPT_DIR}/01-bootstrap/proxmox/README.md"

  test_case "README has main heading"
  assert_file_contains "$readme" "^# Proxmox VE 8.2"

  test_case "README has prerequisites section"
  assert_file_contains "$readme" "^## Prerequisites"

  test_case "README has installation section"
  assert_file_contains "$readme" "^## Installation Steps"

  test_case "README has usage examples"
  assert_file_contains "$readme" "^## Usage Examples"

  test_case "README has troubleshooting"
  assert_file_contains "$readme" "^## Troubleshooting"

  test_case "README has security guarantees"
  assert_file_contains "$readme" "^## Security Guarantees"

  test_case "README documents each phase"
  assert_file_contains "$readme" "^### Phase"
}

################################################################################
# SUITE 9: IDEMPOTENCE & RECOVERY
################################################################################

suite_idempotence() {
  echo -e "\n${BLUE}TEST SUITE 9: Idempotence & Recovery${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Script backs up existing SSH config"
  assert_file_contains "$SCRIPT_PATH" "sshd_config.bak"

  test_case "Script backs up existing network config"
  assert_file_contains "$SCRIPT_PATH" "interfaces.bak"

  test_case "Script checks if directory exists before cloning"
  assert_file_contains "$SCRIPT_PATH" "\-d \"\$REPO_DIR\""

  test_case "Script uses idempotent sed for config updates"
  assert_file_contains "$SCRIPT_PATH" "sed -i"

  test_case "Script uses grep for safe config checks"
  assert_file_contains "$SCRIPT_PATH" "grep -q"
}

################################################################################
# SUITE 10: CODE QUALITY METRICS
################################################################################

suite_code_metrics() {
  echo -e "\n${BLUE}TEST SUITE 10: Code Quality Metrics${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  test_case "Calculate line count metrics"

  local total_lines
  total_lines=$(wc -l <"$SCRIPT_PATH")

  local code_lines
  code_lines=$(grep -vc "^[[:space:]]*#" "$SCRIPT_PATH" || echo 0)

  local comment_lines
  comment_lines=$(grep -c "^[[:space:]]*#" "$SCRIPT_PATH" || echo 0)

  local function_count
  function_count=$(grep -c "^[a-z_][a-z_]*() {" "$SCRIPT_PATH" || echo 0)

  if [ "$code_lines" -le 500 ]; then
    test_pass "Code complexity within limits (Unix Philosophy: $code_lines LOC ≤ 500)"
  else
    test_fail "Code complexity excessive ($code_lines LOC > 500)"
  fi

  test_case "Check comment density"

  local comment_density=$((comment_lines * 100 / total_lines))
  if [ "$comment_density" -ge 20 ]; then
    test_pass "Good comment density: $comment_density% ($comment_lines/$total_lines lines)"
  else
    test_warn "Low comment density: $comment_density% (target: ≥20%)"
  fi

  test_case "Check modularization"

  if [ "$function_count" -ge 10 ]; then
    test_pass "Good modularization: $function_count functions"
  else
    test_fail "Poor modularization: only $function_count functions (target: ≥10)"
  fi
}

################################################################################
# TEST REPORT GENERATION
################################################################################

print_test_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "TEST SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Total Tests:  $TESTS_TOTAL"
  echo "Passed:       ${GREEN}$TESTS_PASSED${NC}"
  echo "Failed:       ${RED}$TESTS_FAILED${NC}"

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    echo ""
    return 0
  else
    echo ""
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    return 1
  fi
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
  echo ""
  echo "████████████████████████████████████████████████████████████████████████████████"
  echo "█                                                                              █"
  echo "█                  Proxmox Ignite Validation Test Suite                       █"
  echo "█                                                                              █"
  echo "████████████████████████████████████████████████████████████████████████████████"

  # Run all test suites
  suite_script_integrity
  suite_script_structure
  suite_argument_validation
  suite_ssh_hardening
  suite_network_configuration
  suite_security_validation
  suite_error_handling
  suite_documentation
  suite_idempotence
  suite_code_metrics

  # Print summary and exit
  print_test_summary
}

# Execute main
main "$@"
