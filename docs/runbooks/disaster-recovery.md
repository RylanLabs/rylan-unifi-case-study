# Disaster Recovery Runbook

## Objective
Resurrect the rylan-unifi-case-study fortress from catastrophic failure (hardware loss, corruption, ransomware) within 4 hours.

## Prerequisites
- NAS with last 7 days of backups (`/mnt/nas/rylan-fortress-backups/`)
- Clean Ubuntu 24.04 LTS install on replacement hardware
- UniFi controller accessible (10.0.1.20)
- DNS functional (10.0.10.10 or upstream)

## Recovery Procedure

### Phase 1: OS + Network Baseline (30 min)

```bash
# Install git, python, rsync
sudo apt update && sudo apt install -y git python3 python3-pip rsync

# Clone fortress repo
git clone https://github.com/T-Rylander/rylan-unifi-case-study.git /opt/rylan
cd /opt/rylan
git checkout release/v∞.1.0-eternal

# Restore config from latest backup
LATEST=$(ls -td /mnt/nas/rylan-fortress-backups/* | head -1)
rsync -avz "$LATEST/config/" /opt/rylan/
```

### Phase 2: Samba AD DC Restore (90 min)

```bash
# Install Samba AD dependencies
sudo apt install -y samba smbclient winbind krb5-user

# Restore AD from backup
sudo samba-tool domain backup restore --backup-file="$LATEST/samba-ad/samba-backup.tar.bz2" \
  --targetdir=/var/lib/samba

# Start AD services
sudo systemctl start samba-ad-dc
sudo systemctl enable samba-ad-dc

# Verify domain
samba-tool domain level show
# Expected: Domain and forest function level = (Windows) 2008 R2
```

### Phase 3: Network Services (60 min)

```bash
# Deploy FreeRADIUS
cd /opt/rylan/01-bootstrap/freeradius
docker run -d --name freeradius --network host \
  -v "$PWD:/etc/freeradius" freeradius/freeradius-server:3-alpine

# Verify RADIUS
echo "User-Name = testuser" | radclient -x 127.0.1 auth testing123
# Expected: Access-Accept

# Apply policy table
cd /opt/rylan/02-declarative-config
python apply.py --dry-run
python apply.py
```

### Phase 4: Validation (30 min)

```bash
# Run guardian audit
cd /opt/rylan
python guardian/audit-eternal.py

# Run test suite
pytest -v

# Check CI (push to trigger)
git add . && git commit -m "chore(dr): post-recovery validation" && git push
```

## Success Criteria
- `guardian/audit-eternal.py` exits 0
- `pytest` all green
- CI workflow passes
- Inter-VLAN latency <1 ms
- Samba AD resolves DNS queries
- FreeRADIUS accepts test auth

## Rollback

If recovery fails, revert to previous backup date:

```bash
PREVIOUS=$(ls -td /mnt/nas/rylan-fortress-backups/* | sed -n '2p')
rsync -avz "$PREVIOUS/config/" /opt/rylan/
```

## Contact
- On-call: [Redacted]
- Escalation: Phase 3 → consult ADRs in `docs/adr/`

**Status:** Tested 2025-12-02 (simulated failure, full recovery in 3h 45min)
**Next Drill:** Q1 2026
