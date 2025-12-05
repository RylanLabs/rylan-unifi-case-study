# Ministry of Whispers — Bauer Hardening (Phase 2)

**Status**: Production-ready  
**Estimated Deployment Time**: <30 seconds (atomic one-shot)  
**Depends On**: Phase 1 (Ministry of Secrets) ✓  
**Rollback**: Restore SSH config and firewall rules from backups

## Overview

The **Ministry of Whispers** enforces the **Bauer 10-rule lockdown**:
- **SSH key-only** authentication (no passwords, no root login)
- **nftables** firewall with drop-default policy
- **fail2ban** intrusion prevention (3600s ban)
- **auditd** comprehensive logging (integrated with guardian/audit-eternal.py)

This phase hardens the fortress against unauthorized access and brute-force attacks.

---

## Quick Deploy (Copy-Paste)

```bash
# 1. Prerequisites: Phase 1 complete
sudo systemctl status samba-ad-dc  # Should be active

# 2. Run Phase 2 (Whispers/Hardening) — Atomic One-Shot
sudo bash ./runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh
```

**Expected output:**
```
[WHISPERS] Phase 2.1: SSH Hardening (Key-only authentication)
✓ SSH hardened (key-only, no password)
✓ nftables loaded with drop-default policy
✓ Fail2Ban configured (3600s ban, max 5 failures)
✓ auditd rules deployed
[✓ SUCCESS] Phase 2 COMPLETE: Ministry of Whispers hardening complete
```

---

## Validation Checklist

After deployment, verify:

- [ ] **SSH password auth disabled**: `grep "^PasswordAuthentication" /etc/ssh/sshd_config` (should be `no`)
- [ ] **SSH root login disabled**: `grep "^PermitRootLogin" /etc/ssh/sshd_config` (should be `no`)
- [ ] **nftables running**: `sudo systemctl status nftables` (should be `active`)
- [ ] **nftables rules loaded**: `sudo nft list ruleset | grep "policy drop"` (should show drop policy)
- [ ] **fail2ban running**: `sudo systemctl status fail2ban` (should be `active`)
- [ ] **auditd running**: `sudo systemctl status auditd` (should be `active`)

---

## SSH Configuration Details

The hardened `sshd_config` includes:

```bash
# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no

# Ciphers (modern, FIPS-compliant)
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Logging
LogLevel VERBOSE
ClientAliveInterval 300  # 5 minutes
```

**Your SSH keys must be deployed** to all administrator accounts before applying Phase 2.

---

## nftables Firewall Rules

The drop-default policy allows:

- **SSH** (port 22) — from anywhere
- **DHCP** (UDP 67/68) — if applicable
- **ICMP** (ping) — for diagnostics
- **Established connections** — state tracking
- **Everything else** → DROP (implicit deny)

To verify rules:

```bash
sudo nft list ruleset
```

---

## fail2ban Configuration

Monitoring: `sshd` authentication failures

**Ban parameters:**
- Max failures: 5
- Time window: 600 seconds (10 minutes)
- Ban duration: 3600 seconds (1 hour)

View bans:

```bash
sudo fail2ban-client status sshd
```

Unban an IP:

```bash
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>
```

---

## Audit Logging

All authentication events are logged to `/var/log/audit/audit.log` and integrated with guardian/audit-eternal.py:

```bash
# View recent audit logs
sudo tail -f /var/log/audit/audit.log | grep ssh

# Search for failed SSH attempts
sudo ausearch -m USER_AUTH -ts recent | head -20
```

---

## Troubleshooting

### SSH connection denied after deployment
**Cause**: SSH key not configured  
**Fix**: Ensure SSH key is in `~/.ssh/authorized_keys` before applying Phase 2

```bash
# On your workstation:
ssh-copy-id admin@10.0.10.10
```

### nftables won't start
```bash
# Check for syntax errors
sudo nft -f /etc/nftables.conf -d

# Restart
sudo systemctl restart nftables
```

### Can't connect after firewall deployment
**Cause**: SSH port blocked  
**Fix**: Use console access or recovery mode

```bash
# At console:
sudo nft flush ruleset
sudo nft -f /etc/nftables.conf
```

### fail2ban too aggressive (legitimate user banned)
```bash
# Unban IP
sudo fail2ban-client set sshd unbanip <YOUR_IP>

# Adjust jail settings (increase maxretry)
sudo vim /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
```

---

## Rollback Procedure

If Phase 2 needs to be reverted:

```bash
# 1. Restore original SSH config
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl reload ssh

# 2. Disable nftables
sudo systemctl stop nftables
sudo systemctl disable nftables

# 3. Disable fail2ban
sudo systemctl stop fail2ban
sudo systemctl disable fail2ban

# 4. Disable auditd (optional)
sudo systemctl stop auditd
```

---

## What Happens Next

Once Phase 2 (Whispers) is complete, proceed to **Phase 3: Ministry of Perimeter** (Suehring policy):

```bash
sudo bash ./runbooks/ministry-perimeter/apply.sh
```

This deploys:
- Policy table (≤10 rules for hardware offload)
- VLAN isolation validation
- Rogue DHCP detection webhook

---

## Key Files

| File | Purpose |
|------|---------|
| `rylan-bauer-eternal-one-shot.sh` | Phase 2 orchestrator (atomic, <30s) |
| `README.md` | This file |
| `/etc/ssh/sshd_config.d/99-bauer-eternal.conf` | Hardened SSH configuration (key-only) |
| `/etc/nftables.conf` | Firewall ruleset (drop-default policy) |
| `/etc/fail2ban/jail.local` | fail2ban configuration |

---

## Security Notes

🔐 **Key-only SSH is mandatory before production deployment.**  
🔐 **SSH keys must be provisioned before Phase 2.**  
🔐 **Keep SSH keys secure** (not in Git, .env, or shared drives).  
🔐 **nftables drop-default policy blocks all unexpected traffic.**

---

## Questions?

Run the deployment with verbose logging:

```bash
bash -x ./runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh
```

Check comprehensive status:

```bash
sudo sshd -T  # SSH configuration test
sudo nft list ruleset  # Firewall rules
sudo fail2ban-client status  # fail2ban status
```
