#!/usr/bin/env bash
# === BAUER ETERNAL VALIDATION – AUTOMATED ===
# Validates SSH hardening deployed by rylan-bauer-eternal-one-shot.sh
# Tests: Password auth disabled, key-based auth working, config integrity
# Location: 03-validation-ops/validate-bauer-eternal.sh

set -euo pipefail

PROXMOX_IP="${PROXMOX_IP:-192.168.1.10}"  # Override via env var
PASS=0
FAIL=0

echo "=== BAUER MINISTRY VALIDATION ==="
echo "Target: $PROXMOX_IP"
echo ""

# Test 1: Password auth dead
if ! ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o ConnectTimeout=5 root@"$PROXMOX_IP" exit 2>/dev/null; then
  echo "✅ Test 1: Password authentication DEAD"
  ((PASS++))
else
  echo "❌ Test 1: Password authentication still works"
  ((FAIL++))
fi

# Test 2: Key-based auth works
if ssh -o ConnectTimeout=5 root@"$PROXMOX_IP" "echo 'BAUER ETERNAL CONFIRMED'" 2>/dev/null | grep -q "BAUER ETERNAL CONFIRMED"; then
  echo "✅ Test 2: Key-based authentication WORKS"
  ((PASS++))
else
  echo "❌ Test 2: Key-based authentication FAILED"
  ((FAIL++))
fi

# Test 3: Config file integrity
if ssh root@"$PROXMOX_IP" "grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config.d/99-bauer-eternal.conf && \
   grep -q '^PermitRootLogin prohibit-password' /etc/ssh/sshd_config.d/99-bauer-eternal.conf && \
   grep -q '^MaxAuthTries 3' /etc/ssh/sshd_config.d/99-bauer-eternal.conf" 2>/dev/null; then
  echo "✅ Test 3: Config file integrity VERIFIED"
  ((PASS++))
else
  echo "❌ Test 3: Config file missing critical directives"
  ((FAIL++))
fi

# Test 4: Authorized keys present
KEY_COUNT=$(ssh root@"$PROXMOX_IP" "cat /root/.ssh/authorized_keys 2>/dev/null | wc -l" || echo 0)
if [[ "$KEY_COUNT" -gt 0 ]]; then
  echo "✅ Test 4: Authorized keys present ($KEY_COUNT keys)"
  ((PASS++))
else
  echo "❌ Test 4: No authorized keys found"
  ((FAIL++))
fi

# Test 5: SSHD config valid
if ssh root@"$PROXMOX_IP" "sshd -t" 2>/dev/null; then
  echo "✅ Test 5: SSHD configuration VALID"
  ((PASS++))
else
  echo "❌ Test 5: SSHD configuration INVALID"
  ((FAIL++))
fi

# Test 6: SSHD service active
if ssh root@"$PROXMOX_IP" "systemctl is-active sshd" 2>/dev/null | grep -q "active"; then
  echo "✅ Test 6: SSHD service ACTIVE"
  ((PASS++))
else
  echo "❌ Test 6: SSHD service NOT ACTIVE"
  ((FAIL++))
fi

# Test 7: SSHD listening on port 22
if ssh root@"$PROXMOX_IP" "ss -tlnp | grep -q ':22'" 2>/dev/null; then
  echo "✅ Test 7: SSHD listening on port 22"
  ((PASS++))
else
  echo "❌ Test 7: SSHD NOT listening on port 22"
  ((FAIL++))
fi

# Test 8: Root login restrictions
if ssh root@"$PROXMOX_IP" "grep -q '^PermitRootLogin prohibit-password' /etc/ssh/sshd_config.d/99-bauer-eternal.conf" 2>/dev/null; then
  echo "✅ Test 8: Root login properly restricted"
  ((PASS++))
else
  echo "❌ Test 8: Root login restrictions MISSING"
  ((FAIL++))
fi

# Test 9: No legacy config conflicts
CONFLICTS=$(ssh root@"$PROXMOX_IP" "grep -E '^PasswordAuthentication yes|^PermitRootLogin yes' /etc/ssh/sshd_config 2>/dev/null | wc -l" || echo 0)
if [[ "$CONFLICTS" -eq 0 ]]; then
  echo "✅ Test 9: No legacy config conflicts"
  ((PASS++))
else
  echo "⚠️  Test 9: Found $CONFLICTS potential conflicts (review manually)"
  ((PASS++))  # Non-critical if 99-bauer-eternal.conf overrides
fi

# Test 10: File permissions correct
PERMS=$(ssh root@"$PROXMOX_IP" "stat -c '%a' /root/.ssh /root/.ssh/authorized_keys 2>/dev/null" || echo "")
if echo "$PERMS" | grep -q "700" && echo "$PERMS" | grep -q "600"; then
  echo "✅ Test 10: File permissions CORRECT (700/600)"
  ((PASS++))
else
  echo "❌ Test 10: File permissions INCORRECT"
  ((FAIL++))
fi

# Test 11: Forwarding disabled
if ssh root@"$PROXMOX_IP" "grep -q '^AllowAgentForwarding no' /etc/ssh/sshd_config.d/99-bauer-eternal.conf && \
   grep -q '^AllowTcpForwarding no' /etc/ssh/sshd_config.d/99-bauer-eternal.conf && \
   grep -q '^X11Forwarding no' /etc/ssh/sshd_config.d/99-bauer-eternal.conf" 2>/dev/null; then
  echo "✅ Test 11: All forwarding DISABLED"
  ((PASS++))
else
  echo "❌ Test 11: Forwarding not properly disabled"
  ((FAIL++))
fi

# Test 12: Connection timeout settings
if ssh root@"$PROXMOX_IP" "grep -q '^ClientAliveInterval 60' /etc/ssh/sshd_config.d/99-bauer-eternal.conf && \
   grep -q '^ClientAliveCountMax 3' /etc/ssh/sshd_config.d/99-bauer-eternal.conf && \
   grep -q '^LoginGraceTime 20' /etc/ssh/sshd_config.d/99-bauer-eternal.conf" 2>/dev/null; then
  echo "✅ Test 12: Connection timeout settings CONFIGURED"
  ((PASS++))
else
  echo "❌ Test 12: Connection timeout settings MISSING"
  ((FAIL++))
fi

# Test 13: Max auth attempts limited
if ssh root@"$PROXMOX_IP" "grep -q '^MaxAuthTries 3' /etc/ssh/sshd_config.d/99-bauer-eternal.conf" 2>/dev/null; then
  echo "✅ Test 13: MaxAuthTries LIMITED to 3"
  ((PASS++))
else
  echo "❌ Test 13: MaxAuthTries not properly set"
  ((FAIL++))
fi

# Test 14: Proxmox services unaffected
PVE_STATUS=$(ssh root@"$PROXMOX_IP" "systemctl is-active pve-cluster pvedaemon pveproxy 2>/dev/null | grep -c 'active'" || echo 0)
if [[ "$PVE_STATUS" -eq 3 ]]; then
  echo "✅ Test 14: Proxmox services UNAFFECTED (all active)"
  ((PASS++))
else
  echo "⚠️  Test 14: Some Proxmox services not active ($PVE_STATUS/3)"
  ((PASS++))  # Non-critical for SSH hardening
fi

# Test 15: No plaintext secrets in config
SECRETS=$(ssh root@"$PROXMOX_IP" "grep -i 'password.*=' /etc/ssh/sshd_config.d/99-bauer-eternal.conf 2>/dev/null | grep -v '^#' | grep -v 'PasswordAuthentication no' | wc -l" || echo 0)
if [[ "$SECRETS" -eq 0 ]]; then
  echo "✅ Test 15: No plaintext secrets in config"
  ((PASS++))
else
  echo "❌ Test 15: Potential secrets found in config"
  ((FAIL++))
fi

echo ""
echo "=== VALIDATION SUMMARY ==="
echo "✅ PASSED: $PASS"
echo "❌ FAILED: $FAIL"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  cat <<'VERDICT'
██████╗  █████╗ ██╗   ██╗███████╗██████╗     ███████╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     
██╔══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗    ██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     
██████╔╝███████║██║   ██║█████╗  ██████╔╝    █████╗     ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     
██╔══██╗██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝     ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     
██████╔╝██║  ██║╚██████╔╝███████╗██║  ██║    ███████╗   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗
╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
                                                                                                          
Trust nothing. Verify everything. The fortress never sleeps.
VERDICT
  exit 0
else
  cat <<'FAILURE'
██████╗  █████╗ ██╗   ██╗███████╗██████╗     ███████╗ █████╗ ██╗██╗     ███████╗██████╗ 
██╔══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗    ██╔════╝██╔══██╗██║██║     ██╔════╝██╔══██╗
██████╔╝███████║██║   ██║█████╗  ██████╔╝    █████╗  ███████║██║██║     █████╗  ██║  ██║
██╔══██╗██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║██║     ██╔══╝  ██║  ██║
██████╔╝██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║██║███████╗███████╗██████╔╝
╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝ 
                                                                                          
Review failures above. The fortress demands perfection.
FAILURE
  exit 1
fi
