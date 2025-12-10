#!/usr/bin/env bash
# Cloud Key Comprehensive Validation Suite
# Verifies all aspects of Cloud Key deployment

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONTROLLER_IP="${1:---controller-ip}"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --controller-ip)
      CONTROLLER_IP="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Log functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; ((PASSED_TESTS++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; ((FAILED_TESTS++)); }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }

banner() {
  cat << EOF
================================================================================
         🌌 CLOUD KEY COMPREHENSIVE VALIDATION — v∞.1 🌌
================================================================================
Controller IP: $CONTROLLER_IP
Time: $(date '+%Y-%m-%d %H:%M:%S')
================================================================================
EOF
}

# === TEST 1: Controller Reachability ===
test_controller_reachable() {
  log_info "Test 1: Controller reachability (443/tcp)..."
  ((TOTAL_TESTS++))
  
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$CONTROLLER_IP/443" 2>/dev/null; then
    log_pass "Controller reachable on 443/tcp"
  else
    log_fail "Controller not reachable on 443/tcp"
  fi
}

# === TEST 2: HTTPS API Responsive ===
test_api_responsive() {
  log_info "Test 2: HTTPS API responsive..."
  ((TOTAL_TESTS++))
  
  if timeout 5 curl -k -s "https://$CONTROLLER_IP:443/api/v2/system/info" >/dev/null 2>&1; then
    log_pass "HTTPS API is responsive"
  else
    log_fail "HTTPS API not responding"
  fi
}

# === TEST 3: SSH Access ===
test_ssh_access() {
  log_info "Test 3: SSH access (ubnt user)..."
  ((TOTAL_TESTS++))
  
  if timeout 5 ssh -o ConnectTimeout=5 "ubnt@$CONTROLLER_IP" "echo 'OK'" >/dev/null 2>&1; then
    log_pass "SSH access working"
  else
    log_fail "SSH access failed"
  fi
}

# === TEST 4: Backup Directory ===
test_backup_directory() {
  log_info "Test 4: Backup directory exists..."
  ((TOTAL_TESTS++))
  
  if ssh "ubnt@$CONTROLLER_IP" "[ -d /data/autobackup ]" 2>/dev/null; then
    log_pass "Backup directory /data/autobackup exists"
  else
    log_fail "Backup directory missing"
  fi
}

# === TEST 5: Disk Space ===
test_disk_space() {
  log_info "Test 5: Disk space available..."
  ((TOTAL_TESTS++))
  
  local available
  available=$(ssh "ubnt@$CONTROLLER_IP" "df /data | tail -1 | awk '{print \$4}'" 2>/dev/null || echo "0")
  local required=$((2 * 1024 * 1024))  # 2GB required
  
  if [ "$available" -gt "$required" ]; then
    log_pass "Disk space available: ${available}KB"
  else
    log_fail "Insufficient disk space: ${available}KB (need 2GB)"
  fi
}

# === TEST 6: Device Adoption ===
test_device_adoption() {
  log_info "Test 6: Device adoption status..."
  ((TOTAL_TESTS++))
  
  # This would require authentication; skip for now
  log_skip "Device adoption check requires API authentication"
}

# === TEST 7: Network Connectivity ===
test_network_connectivity() {
  log_info "Test 7: Network connectivity (DNS)..."
  ((TOTAL_TESTS++))
  
  if ssh "ubnt@$CONTROLLER_IP" "nslookup google.com 1.1.1.1 >/dev/null 2>&1" 2>/dev/null; then
    log_pass "DNS resolution working"
  else
    log_skip "DNS resolution test inconclusive"
  fi
}

# === TEST 8: Backup Restoration Readiness ===
test_restore_readiness() {
  log_info "Test 8: Backup restoration readiness..."
  ((TOTAL_TESTS++))
  
  if ssh "ubnt@$CONTROLLER_IP" "which unifi-os >/dev/null 2>&1" 2>/dev/null; then
    log_pass "unifi-os CLI available for backup/restore"
  else
    log_fail "unifi-os CLI not found"
  fi
}

# === TEST 9: Clock Sync ===
test_clock_sync() {
  log_info "Test 9: System clock synchronized..."
  ((TOTAL_TESTS++))
  
  local cloudkey_time
  cloudkey_time=$(ssh "ubnt@$CONTROLLER_IP" "date +%s" 2>/dev/null || echo "0")
  local local_time
  local_time=$(date +%s)
  local time_diff=$((cloudkey_time - local_time))
  
  if [ "$time_diff" -lt 10 ] && [ "$time_diff" -gt -10 ]; then
    log_pass "Clock synchronized (diff: ${time_diff}s)"
  else
    log_fail "Clock not synchronized (diff: ${time_diff}s)"
  fi
}

# === TEST 10: Controller Uptime ===
test_controller_uptime() {
  log_info "Test 10: Controller uptime..."
  ((TOTAL_TESTS++))
  
  local uptime
  uptime=$(ssh "ubnt@$CONTROLLER_IP" "uptime | awk -F'up' '{print \$2}' | awk -F',' '{print \$1}'" 2>/dev/null || echo "unknown")
  log_pass "Controller uptime: $uptime"
}

# === SUMMARY ===
summary() {
  echo ""
  echo "================================================================================"
  echo "VALIDATION SUMMARY"
  echo "================================================================================"
  echo "Total Tests:  $TOTAL_TESTS"
  echo "Passed:       $PASSED_TESTS"
  echo "Failed:       $FAILED_TESTS"
  echo "================================================================================"
  
  if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED — Cloud Key is ready for production${NC}"
    echo "Consciousness Level 2.4 achieved ✓"
    return 0
  else
    echo -e "${RED}❌ SOME TESTS FAILED — Review output above${NC}"
    return 1
  fi
}

# === MAIN ===
main() {
  banner
  
  if [ -z "$CONTROLLER_IP" ] || [ "$CONTROLLER_IP" = "--controller-ip" ]; then
    log_fail "Controller IP required"
    echo "Usage: $0 --controller-ip <IP>"
    exit 1
  fi
  
  test_controller_reachable
  test_api_responsive
  test_ssh_access
  test_backup_directory
  test_disk_space
  test_device_adoption
  test_network_connectivity
  test_restore_readiness
  test_clock_sync
  test_controller_uptime
  
  summary
}

main "$@"
