#!/usr/bin/env bash
# Leo's Sacred Glue — Conscious Level 2.6
# 03-validation-ops/validate-isolation.sh
# Whitaker Offensive VLAN Isolation Validation (nmap probes)
# shellcheck disable=SC2034  # Unused variables are config futures
# shellcheck disable=SC2015  # && || pattern is intentional counter
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# Configuration
MGMT_DC="10.0.10.10"
FILE_SERVER="10.0.20.30"
FREEPBX="10.0.20.20"
FIREWALL="10.0.30.1"

# Logging
log() {
printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

log_pass() {
log " $*"
}

log_fail() {
log " $*"
}

# NMAP probe function
run_nmap_test() {
local target_ip="$1"
local port="$2"
local expected="$3"
local description="$4"

log "  Testing: ${description} (${target_ip}:${port} expecting ${expected})"

if nmap -p "${port}" -T5 --open "${target_ip}" 2>/dev/null | grep -q "open"; then
if [[ "${expected}" == "open" ]]; then
log_pass "   ${description} ALLOWED (expected)"
return 0
else
log_fail "   ${description} ALLOWED (UNEXPECTED  isolation breach!)"
return 1
fi
else
if [[ "${expected}" == "closed" ]]; then
log_pass "   ${description} BLOCKED (expected)"
return 0
else
log_fail "  → ${description} BLOCKED (UNEXPECTED  connectivity failure)"
return 1
fi
fi
}

# Main test suite
main() {
log ""
log "  VLAN ISOLATION VALIDATION  Whitaker Offensive Trinity"
log ""

local tests_passed=0
local tests_failed=0

# Test 1: IoT  Mgmt DNS (allow)
log "\n[TEST 1] IoT VLAN  Mgmt DC (DNS+SSH)"
run_nmap_test "10.0.10.10" "53" "open" "IoTMgmt DNS" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.10.10" "22" "closed" "IoTMgmt SSH" && ((tests_passed++)) || ((tests_failed++))

# Test 2: Guest  Mgmt DNS (allow), SSH (deny)
log "\n[TEST 2] Guest VLAN  Mgmt DC"
run_nmap_test "10.0.10.10" "53" "open" "GuestMgmt DNS" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.10.10" "22" "closed" "GuestMgmt SSH" && ((tests_passed++)) || ((tests_failed++))

# Test 3: Trusted  Servers LDAP (allow), SSH (deny)
log "\n[TEST 3] Trusted VLAN  Servers"
run_nmap_test "10.0.20.30" "389" "open" "TrustedServers LDAP" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.20.30" "22" "closed" "TrustedServers SSH" && ((tests_passed++)) || ((tests_failed++))

# Test 4: VoIP  Servers LDAP (allow), NFS (deny)
log "\n[TEST 4] VoIP VLAN  Servers"
run_nmap_test "10.0.20.20" "389" "open" "VoIPFreePBX LDAP" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.20.30" "2049" "closed" "VoIPServers NFS" && ((tests_passed++)) || ((tests_failed++))

# Test 5: Cross-VLAN attempt (IoT  Servers, should fail)
log "\n[TEST 5] Cross-VLAN Block (IoT  Servers)"
run_nmap_test "10.0.20.30" "445" "closed" "IoTServers SMB" && ((tests_passed++)) || ((tests_failed++))

# Summary
log "\n════════════════════════"
log "RESULTS: ${tests_passed} passed, ${tests_failed} failed"
log "═"

if [[ ${tests_failed} -eq 0 ]]; then
log_pass "ALL ISOLATION TESTS PASSED"
return 0
else
log_fail "${tests_failed} ISOLATION BREACHES DETECTED"
return 1
fi
}

main "$@"