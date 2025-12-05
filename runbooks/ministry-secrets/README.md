# Ministry of Secrets — Carter Capstone (Phase 1)

**Status**: Production-ready  
**Estimated Deployment Time**: <30 seconds (atomic one-shot)  
**Rollback**: Restore from backup or re-image with clean Ubuntu 24.04

## Overview

The **Ministry of Secrets** is the foundational phase that establishes the core identity infrastructure:
- **Samba AD/DC** with DNS forwarding to Pi-hole
- **LDAP** group-based authentication (LDAPS port 636)
- **Kerberos** service authentication (realm: RYLAN.INTERNAL)
- **NFS** Kerberos-secured mount (sec=krb5p)

This phase is **required** before Phases 2 and 3.

---

## Quick Deploy (Copy-Paste)

```bash
# 1. SSH into rylan-dc
ssh admin@10.0.10.10

# 2. Clone or update repo
cd /root/rylan-unifi-case-study
git pull origin feat/iot-production-ready

# 3. Load environment
source .env

# 4. Run Phase 1 (Secrets) — Atomic One-Shot
sudo bash ./runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
```

**Expected output:**
```
[SECRETS] Phase 1.1: Samba AD/DC Provisioning
✓ Samba AD/DC service active
✓ Keytabs exported and locked (600)
✓ FreeRADIUS service account created
✓ UniFi admin group exists
[✓ SUCCESS] Phase 1 COMPLETE: Ministry of Secrets foundation established
```

---

## Validation Checklist

After deployment, verify:

- [ ] **Samba AD/DC service**: `sudo systemctl status samba-ad-dc` (should be `active`)
- [ ] **Kerberos keytab**: `ls -la /etc/krb5.keytab` (should exist, 600 perms)
- [ ] **FreeRADIUS account**: `samba-tool user list | grep freeradius-svc`
- [ ] **UniFi admin group**: `samba-tool group list | grep unifi-admins`
- [ ] **NFS exports** (on rylan-ai): `exportfs -v` (should list /srv/nfs/backups)
- [ ] **Kerberos auth test**: `kinit -t /etc/krb5.keytab admin@RYLAN.INTERNAL` (should succeed)

---

## Troubleshooting

### Samba AD/DC fails to start
```bash
# Check logs
journalctl -u samba-ad-dc -n 50 --no-pager

# Restart
sudo systemctl restart samba-ad-dc
```

### Keytab export fails
```bash
# Verify admin credentials
samba-tool domain info RYLAN.INTERNAL

# Manually export
sudo samba-tool domain exportkeytab /etc/krb5.keytab --principal=admin@RYLAN.INTERNAL
```

### NFS mount fails (on clients)
```bash
# Ensure Kerberos ticket exists
kinit -t /etc/krb5.keytab admin@RYLAN.INTERNAL
klist

# Mount with Kerberos
mount -t nfs -o sec=krb5p 10.0.10.60:/srv/nfs/backups /mnt/backup
```

---

## Rollback Procedure

If Phase 1 deployment fails or needs to be reverted:

```bash
# 1. Stop Samba AD/DC
sudo systemctl stop samba-ad-dc

# 2. Restore from backup (if available)
sudo samba-tool domain backup restore --backup-file=/path/to/backup.tar.bz2

# 3. Or, re-image and start over
# This is the most reliable approach
```

---

## What Happens Next

Once Phase 1 (Secrets) is complete, proceed to **Phase 2: Ministry of Whispers** (Bauer hardening):

```bash
sudo bash ./runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh
```

This deploys:
- SSH key-only authentication (no password login)
- nftables firewall with drop-default policy
- fail2ban intrusion prevention
- Audit logging integration

---

## Key Files

| File | Purpose |
|------|---------|
| `rylan-carter-eternal-one-shot.sh` | Phase 1 orchestrator (atomic, <30s) |
| `README.md` | This file |
| `../../../.env` | Environment variables (Samba realm, IPs, etc.) |

---

## Questions?

Run the deployment with verbose logging:

```bash
bash -x ./runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
```

For detailed status:

```bash
sudo samba-tool domain info RYLAN.INTERNAL
sudo samba-tool user list
sudo samba-tool group list
```
