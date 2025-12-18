#!/usr/bin/env bash
# Script: 03_validation_ops/validate-isolation.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6
# Leo's Sacred Glue — Conscious Level 2.6
# 03_validation_ops/validate-isolation.sh
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
# shellcheck disable=SC2034
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

	# CI_MODE: Skip nmap probes (no live network in CI)
	if [[ "${CI_MODE:-}" == "1" ]]; then
		log "⚠ CI_MODE: Skipping nmap probes (no live infrastructure)"
		log "  In production, this validates:"
		log "  - IoT→DNS (open), IoT→SSH (closed)"
		log "  - Guest→DNS (open), Guest→SSH (closed)"
		log "  - Trusted→LDAP (open), Trusted→SSH (closed)"
		log "  - VoIP→LDAP (open), VoIP→NFS (closed)"
		log "  - Cross-VLAN→SMB (closed)"
		log "  - Quarantine→All Internal (closed), Quarantine→Internet (open)"
		log ""
		log_pass "CI_MODE: Isolation tests deferred to live environment"
		return 0
	fi

	local tests_passed=0
	local tests_failed=0

	# Test 1: IoT  Mgmt DNS (allow)
	log "\n[TEST 1] IoT VLAN  Mgmt DC (DNS+SSH)"
	if run_nmap_test "10.0.10.10" "53" "open" "IoTMgmt DNS"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.10.10" "22" "closed" "IoTMgmt SSH"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Test 2: Guest → Mgmt DNS (allow), SSH (deny)
	log "\n[TEST 2] Guest VLAN → Mgmt DC"
	if run_nmap_test "10.0.10.10" "53" "open" "GuestMgmt DNS"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.10.10" "22" "closed" "GuestMgmt SSH"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Test 3: Trusted → Servers LDAP (allow), SSH (deny)
	log "\n[TEST 3] Trusted VLAN → Servers"
	if run_nmap_test "10.0.20.30" "389" "open" "TrustedServers LDAP"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.20.30" "22" "closed" "TrustedServers SSH"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Test 4: VoIP → Servers LDAP (allow), NFS (deny)
	log "\n[TEST 4] VoIP VLAN → Servers"
	if run_nmap_test "10.0.20.20" "389" "open" "VoIPFreePBX LDAP"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.20.30" "2049" "closed" "VoIPServers NFS"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Test 5: Cross-VLAN attempt (IoT → Servers, should fail)
	log "\n[TEST 5] Cross-VLAN Block (IoT → Servers)"
	if run_nmap_test "10.0.20.30" "445" "closed" "IoTServers SMB"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Test 6: Quarantine VLAN 99 Isolation (DadNet — MUST BE BLOCKED)
	log "\n[TEST 6] Quarantine VLAN 99 → All Internal VLANs (MUST BE BLOCKED)"
	if run_nmap_test "10.0.10.10" "22" "closed" "Quarantine→Mgmt SSH"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.30.1" "67" "closed" "Quarantine→Users DHCP"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.40.1" "80" "closed" "Quarantine→IoT HTTP"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi
	if run_nmap_test "10.0.90.1" "443" "closed" "Quarantine→Prod HTTPS"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Test 7: Quarantine → Internet ONLY (allow outbound)
	log "\n[TEST 7] Quarantine VLAN 99 → Internet (MUST BE ALLOWED)"
	if run_nmap_test "1.1.1.1" "443" "open" "Quarantine→Internet HTTPS"; then
		((tests_passed++))
	else
		((tests_failed++))
	fi

	# Summary
	log ""
	log "════════════════════════"
	log "RESULTS: ${tests_passed} passed, ${tests_failed} failed"
	log "════════════════════════"

	if [[ ${tests_failed} -eq 0 ]]; then
		log_pass "ALL ISOLATION TESTS PASSED"
		return 0
	else
		log_fail "${tests_failed} ISOLATION BREACHES DETECTED"
		return 1
	fi
}

main "$@"
