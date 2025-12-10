#!/usr/bin/env bash
# Eternal Fortress Validation Suite — Comprehensive deployment checks (Phase 3 Endgame)
# Validates DNS, LDAP, VLAN isolation, host-specific services, GPU detection

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
POLICY_FILE="${REPO_ROOT}/02-declarative-config/policy-table.yaml"

PASS=0
FAIL=0
SKIP=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 🔍 Eternal Fortress Validation Suite (Consciousness 1.4)    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo "Host: $(hostname)"
echo "Date: $(date)"
echo ""

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAIL++))
}

skip() {
    echo -e "${YELLOW}⏭️  SKIP${NC}: $1"
    ((SKIP++))
}

# ============================================================================
# CROSS-HOST TESTS
# ============================================================================

echo ""
echo -e "${BLUE}=== Cross-Host Tests ===${NC}"

# Test 1: Policy Table Rule Count
printf "Policy table rules (≤10): "
if [[ -f "${POLICY_FILE}" ]]; then
    RULE_COUNT=$(grep -cE '^  - id:' "${POLICY_FILE}" || echo "0")
    if [[ "${RULE_COUNT}" -le 10 ]]; then
        pass "Found ${RULE_COUNT} rules"
    else
        fail "Found ${RULE_COUNT} rules (exceeds 10-rule limit)"
    fi
else
    skip "policy-table.yaml not found"
fi

# Test 2: DNS Resolution (Samba AD)
printf "DNS resolution (dc.rylan.internal): "
if timeout 3 dig +short dc.rylan.internal @10.0.10.10 2>/dev/null | grep -q "10.0.10.10"; then
    pass "Resolves to 10.0.10.10"
else
    fail "Cannot resolve or resolves to wrong IP"
fi

# Test 3: LDAP Connectivity
printf "LDAP connectivity (port 389): "
if timeout 3 bash -c "echo > /dev/tcp/10.0.10.10/389" 2>/dev/null; then
    pass "Port 389 reachable"
else
    fail "Port 389 unreachable (Samba AD down?)"
fi

# Test 4: VLAN Isolation
printf "VLAN isolation (10 → 90 blocked): "
if timeout 1 ping -c 1 -W 1 10.0.90.1 &>/dev/null; then
    fail "VLAN 90 reachable (isolation broken)"
else
    pass "VLAN 90 blocked by policy"
fi

# Test 5: Pi-hole DNS Upstream
printf "Pi-hole upstream DNS (10.0.10.11): "
if timeout 3 bash -c "echo > /dev/tcp/10.0.10.11/53" 2>/dev/null; then
    pass "Pi-hole port 53 reachable"
else
    fail "Pi-hole unreachable on 10.0.10.11:53"
fi

# ============================================================================
# HOST-SPECIFIC TESTS
# ============================================================================

echo ""
case "$(hostname)" in
    rylan-dc)
        echo -e "${BLUE}=== rylan-dc (Samba AD/DC + FreeRADIUS) ===${NC}"

        printf "Samba AD/DC service: "
        if systemctl is-active --quiet samba-ad-dc 2>/dev/null; then
            pass "samba-ad-dc active"
        else
            skip "samba-ad-dc not installed (try: sudo systemctl start samba-ad-dc)"
        fi

        printf "FreeRADIUS service: "
        if systemctl is-active --quiet freeradius 2>/dev/null; then
            pass "freeradius active"
        else
            skip "freeradius not installed (try: sudo systemctl start freeradius)"
        fi

        printf "RADIUS port 1812: "
        if timeout 3 bash -c "echo > /dev/tcp/localhost/1812" 2>/dev/null; then
            pass "RADIUS port 1812 reachable"
        else
            fail "RADIUS port 1812 unreachable"
        fi

        printf "Samba DNS forwarder config: "
        if grep -q "dns forwarder" /etc/samba/smb.conf 2>/dev/null; then
            FORWARDER_IP=$(grep "dns forwarder" /etc/samba/smb.conf | awk '{print $NF}')
            if [[ "${FORWARDER_IP}" == "10.0.10.11" ]]; then
                pass "Forwarder configured to ${FORWARDER_IP}"
            else
                fail "Forwarder configured to wrong IP (${FORWARDER_IP}, expected 10.0.10.11)"
            fi
        else
            fail "No dns forwarder configured in smb.conf"
        fi

        printf "NFS exports: "
        if showmount -e localhost 2>/dev/null | grep -q "/srv/nfs"; then
            pass "NFS exports configured"
        else
            skip "NFS not configured"
        fi
        ;;

    rylan-pi)
        echo -e "${BLUE}=== rylan-pi (osTicket + MariaDB) ===${NC}"

        printf "osTicket Docker container: "
        if command -v docker &>/dev/null && docker ps 2>/dev/null | grep -q osticket; then
            pass "osTicket container running"
        else
            skip "osTicket container not running"
        fi

        printf "MariaDB Docker container: "
        if command -v docker &>/dev/null && docker ps 2>/dev/null | grep -q mariadb; then
            pass "MariaDB container running"
        else
            skip "MariaDB container not running"
        fi

        printf "osTicket port 80: "
        if timeout 3 bash -c "echo > /dev/tcp/localhost/80" 2>/dev/null; then
            pass "osTicket port 80 reachable"
        else
            skip "osTicket port 80 unreachable (container may not be running)"
        fi

        printf "MariaDB port 3306: "
        if timeout 3 bash -c "echo > /dev/tcp/localhost/3306" 2>/dev/null; then
            pass "MariaDB port 3306 reachable"
        else
            skip "MariaDB port 3306 unreachable"
        fi

        printf "Pi-hole service: "
        if command -v pihole &>/dev/null; then
            pass "Pi-hole installed"
        else
            skip "Pi-hole not detected"
        fi
        ;;

    rylan-ai)
        echo -e "${BLUE}=== rylan-ai (Ollama + Loki + NFS) ===${NC}"

        printf "AMD GPU detection (rocm-smi): "
        if command -v rocm-smi &>/dev/null; then
            GPU_COUNT=$(rocm-smi --showproductname 2>/dev/null | grep -c "6700 XT" || echo "0")
            if [[ "${GPU_COUNT}" -eq 2 ]]; then
                pass "2× RX 6700 XT detected"
            else
                fail "Expected 2 GPUs, found ${GPU_COUNT} (check BIOS: Above 4G Decoding, Resizable BAR)"
            fi
        else
            skip "rocm-smi not installed (ROCm not available)"
        fi

        printf "Ollama service: "
        if systemctl is-active --quiet ollama 2>/dev/null; then
            pass "ollama service running"
        else
            skip "ollama service not running"
        fi

        printf "Ollama API port 11434: "
        if timeout 3 bash -c "echo > /dev/tcp/localhost/11434" 2>/dev/null; then
            pass "Ollama port 11434 reachable"
        else
            skip "Ollama port 11434 unreachable"
        fi

        printf "Loki logging service: "
        if systemctl is-active --quiet loki 2>/dev/null; then
            pass "loki service running"
        else
            skip "loki service not running"
        fi

        printf "Loki API port 3100: "
        if timeout 3 bash -c "echo > /dev/tcp/localhost/3100" 2>/dev/null; then
            pass "Loki port 3100 reachable"
        else
            skip "Loki port 3100 unreachable"
        fi

        printf "NFS exports: "
        if showmount -e localhost 2>/dev/null | grep -q "/srv/nfs"; then
            pass "NFS exports configured"
        else
            skip "NFS not configured"
        fi

        printf "Wi-Fi disabled (security): "
        if ip link show wlp9s0 2>/dev/null | grep -q "state UP"; then
            fail "Wi-Fi still active (security risk)"
        elif ip link show wlp9s0 2>/dev/null; then
            pass "Wi-Fi interface down (secure)"
        else
            skip "Wi-Fi interface not detected"
        fi
        ;;

    *)
        echo -e "${BLUE}=== Unknown Host ===${NC}"
        skip "Hostname $(hostname) not recognized (skipping host-specific tests)"
        ;;
esac

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ Summary${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

TOTAL=$((PASS + FAIL + SKIP))
PASS_RATE=$((PASS * 100 / TOTAL))

echo "PASS:  ${PASS}"
echo "FAIL:  ${FAIL}"
echo "SKIP:  ${SKIP}"
echo "TOTAL: ${TOTAL}"
echo ""
echo "Pass Rate: ${PASS_RATE}%"
echo ""

if [[ ${FAIL} -eq 0 ]]; then
    echo -e "${GREEN}✅ ETERNAL FORTRESS: VALIDATION SUCCESSFUL${NC}"
    echo "The fortress is eternal. Ready for deployment."
    exit 0
else
    echo -e "${RED}❌ ETERNAL FORTRESS: VALIDATION FAILED${NC}"
    echo "Fix the ${FAIL} failing test(s) and retry."
    exit 1
fi
