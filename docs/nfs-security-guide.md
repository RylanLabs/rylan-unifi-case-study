# NFS Security Configuration — Phase 3 Endgame

Domain-based (Kerberos) authentication for secure NFS backups across the eternal fortress.

## Overview

**Challenge**: Multi-host backup requires NFS shares accessible from rylan-dc, rylan-pi, and rylan-ai without compromising security.

**Solution**: Kerberos-authenticated NFS (sec=krb5p) with:
- Authentication via Samba AD/DC (10.0.10.10)
- Integrity checking (no tampering)
- Privacy/encryption (nfs-sec=krb5p)
- Host-specific exports (least privilege)

## Architecture

```
Samba AD/DC (rylan-dc)
│
├─ Kerberos Realm: RYLAN.INTERNAL
├─ Service Principal: nfs/rylan-ai.rylan.internal@RYLAN.INTERNAL
└─ Keytab: /etc/krb5.keytab (shared with NFS server)

NFS Server (rylan-ai)
│
├─ Exports:
│  ├─ /srv/nfs/backups/loki-chunks     → rylan-dc (krb5p)
│  ├─ /srv/nfs/backups/loki-index      → rylan-dc (krb5p)
│  ├─ /srv/nfs/backups/samba           → rylan-dc (krb5p)
│  ├─ /srv/nfs/backups/freeradius      → rylan-dc (krb5p)
│  ├─ /srv/nfs/backups/osticket        → rylan-pi (krb5p)
│  └─ /srv/nfs/backups/qdrant          → rylan-ai (krb5p)

NFS Clients
│
├─ rylan-dc (Samba host)
│  └─ /mnt/nfs/backups → orchestrator.sh backup target
├─ rylan-pi (osTicket host)
│  └─ /mnt/nfs/backups → osticket backup destination
└─ rylan-ai (GPU host)
   └─ /srv/nfs/backups (NFS server, no client mount needed)
```

## Security Properties

| Property | Value | Benefit |
|----------|-------|---------|
| Authentication | Kerberos (RYLAN.INTERNAL) | Domain-based, no shared passwords |
| Integrity | HMAC-MD5 | Detects tampering in transit |
| Privacy | RC4/AES encryption | Encrypted backup data on wire |
| Authorization | Export-level ACL | Per-host IP + service principal |
| Audit Trail | Samba AD logs | All auth attempts logged to DC |

---

## Setup Steps

### Phase 1: NFS Server (rylan-ai)

#### 1.1 Install NFS Server + Kerberos

```bash
sudo apt-get update
sudo apt-get install -y nfs-kernel-server krb5-user krb5-admin-server
```

#### 1.2 Create Export Directories

```bash
sudo mkdir -p /srv/nfs/backups/{loki-chunks,loki-index,samba,freeradius,osticket,qdrant}
sudo chown nfsnobody:nfsnobody /srv/nfs/backups
sudo chmod 755 /srv/nfs/backups
```

#### 1.3 Generate NFS Service Keytab (On rylan-dc)

```bash
# On rylan-dc (Samba AD host)
sudo samba-tool domain exportkeytab /tmp/nfs.keytab \
  --principal=nfs/rylan-ai.rylan.internal@RYLAN.INTERNAL
sudo chmod 600 /tmp/nfs.keytab

# Transfer to rylan-ai
scp /tmp/nfs.keytab rylan-ai:/tmp/nfs.keytab

# On rylan-ai
sudo mv /tmp/nfs.keytab /etc/krb5.keytab
sudo chown root:root /etc/krb5.keytab
sudo chmod 600 /etc/krb5.keytab
```

#### 1.4 Configure /etc/exports

```bash
# /etc/exports — NFS Kerberos exports
/srv/nfs/backups/loki-chunks    10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
/srv/nfs/backups/loki-index     10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
/srv/nfs/backups/samba          10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
/srv/nfs/backups/freeradius     10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
/srv/nfs/backups/osticket       10.0.10.11/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
/srv/nfs/backups/qdrant         10.0.10.60/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
```

**Notes**:
- `sec=krb5p`: Kerberos auth + integrity + privacy
- `rw`: Read-write for backup operations
- `async`: Performance (safe for backups)
- `no_subtree_check`: Recommended for modern NFSv4
- `anonuid/anongid`: Map unauthenticated requests to nfsnobody

#### 1.5 Start NFS Services

```bash
sudo exportfs -ra                    # Reload exports
sudo systemctl enable nfs-server
sudo systemctl start nfs-server

# Verify
sudo showmount -e localhost
```

### Phase 2: NFS Clients (rylan-dc, rylan-pi)

#### 2.1 Install NFS Client + Kerberos

```bash
sudo apt-get update
sudo apt-get install -y nfs-common krb5-user krb5-config
```

#### 2.2 Configure Kerberos (`/etc/krb5.conf`)

```ini
[libdefaults]
  default_realm = RYLAN.INTERNAL
  dns_lookup_realm = false
  dns_lookup_kdc = true
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true

[realms]
  RYLAN.INTERNAL = {
    kdc = 10.0.10.10
    admin_server = 10.0.10.10
    default_domain = rylan.internal
  }

[domain_realm]
  .rylan.internal = RYLAN.INTERNAL
  rylan.internal = RYLAN.INTERNAL
```

#### 2.3 Create Mount Point

```bash
sudo mkdir -p /mnt/nfs/backups
```

#### 2.4 Add fstab Entry

```bash
# /etc/fstab entry for permanent mount
10.0.10.60:/srv/nfs/backups /mnt/nfs/backups nfs4 sec=krb5p,vers=4.2,proto=tcp,port=2049,rw,hard,intr,noatime,_netdev 0 0
```

#### 2.5 Authenticate with Kerberos

```bash
# Get Kerberos ticket from Samba AD
kinit RYLAN\\admin@RYLAN.INTERNAL
# (Enter ADMIN_PASSWORD from .env)

# Verify ticket
klist

# Mount NFS
sudo mount -a

# Verify mount
df -h | grep /mnt/nfs
```

### Phase 3: Automated Keytab (Optional)

For automated mounts without interactive authentication, use a service principal:

#### 3.1 Create Service Account on Samba AD (rylan-dc)

```bash
sudo samba-tool user create backup-nfs --no-password
sudo samba-tool group addmembers "Backup Operators" backup-nfs
```

#### 3.2 Export Keytab

```bash
sudo samba-tool domain exportkeytab /tmp/backup-nfs.keytab \
  --principal=backup-nfs@RYLAN.INTERNAL
sudo chmod 600 /tmp/backup-nfs.keytab

# Copy to NFS clients
scp /tmp/backup-nfs.keytab rylan-dc:/etc/krb5.keytab.backup-nfs
scp /tmp/backup-nfs.keytab rylan-pi:/etc/krb5.keytab.backup-nfs
```

#### 3.3 Auto-Mount in systemd

Create `/etc/systemd/system/mnt-nfs-backups.mount`:

```ini
[Unit]
Description=NFS Backup Mount (Kerberos)
After=network-online.target
Wants=network-online.target

[Mount]
What=10.0.10.60:/srv/nfs/backups
Where=/mnt/nfs/backups
Type=nfs4
Options=sec=krb5p,vers=4.2,proto=tcp,port=2049,rw,hard,intr,noatime
User=backup-nfs

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable mnt-nfs-backups.mount
sudo systemctl start mnt-nfs-backups.mount
```

---

## Verification

### 1. Check NFS Server Exports

```bash
# On rylan-ai
sudo showmount -e localhost
# Output:
# Export list for localhost:
# /srv/nfs/backups/freeradius        10.0.10.10
# /srv/nfs/backups/loki-index        10.0.10.10
# /srv/nfs/backups/loki-chunks       10.0.10.10
# /srv/nfs/backups/osticket          10.0.10.11
# /srv/nfs/backups/qdrant            10.0.10.60
# /srv/nfs/backups/samba             10.0.10.10
```

### 2. Verify Kerberos Ticket

```bash
# On rylan-dc or rylan-pi
klist
# Output:
# Ticket cache: FILE:/tmp/krb5cc_1000
# Default principal: RYLAN\admin@RYLAN.INTERNAL
#
# Valid starting     Expires            Service principal
# 12/03/2025 10:30   12/04/2025 10:30   krbtgt/RYLAN.INTERNAL@RYLAN.INTERNAL
```

### 3. Test NFS Mount

```bash
# On rylan-dc or rylan-pi
sudo mount -t nfs4 -o sec=krb5p 10.0.10.60:/srv/nfs/backups /mnt/nfs/backups

df -h | grep /mnt/nfs
# Output:
# 10.0.10.60:/srv/nfs/backups  <size>  <used>  <avail>  <use%>  /mnt/nfs/backups

sudo ls -la /mnt/nfs/backups/
# Should list backup subdirectories (loki-chunks, samba, etc.)
```

### 4. Test Write Permission

```bash
# On rylan-dc
sudo touch /mnt/nfs/backups/test-dc-$(date +%s).txt
ls -la /mnt/nfs/backups/

# On rylan-pi
sudo touch /mnt/nfs/backups/test-pi-$(date +%s).txt
ls -la /mnt/nfs/backups/

# Verify both files exist on NFS server (rylan-ai)
sudo ls -la /srv/nfs/backups/
```

---

## Troubleshooting

### Mount Fails: "Permission denied"

**Cause**: Kerberos ticket expired or not obtained

**Fix**:
```bash
kinit RYLAN\\admin@RYLAN.INTERNAL
klist
sudo mount -a
```

### Mount Fails: "Server not responding"

**Cause**: NFS server not listening or firewall blocking

**Fix** (on rylan-ai):
```bash
sudo systemctl status nfs-server
sudo showmount -e localhost
# If blocked: check firewall
sudo ufw status
sudo ufw allow 2049/tcp   # NFS
sudo ufw allow 111/tcp    # Portmapper
```

### "sec=krb5p not supported"

**Cause**: NFS version too old or Kerberos utilities missing

**Fix**:
```bash
sudo apt-get install nfs-common krb5-user
# Use NFSv4.2 minimum
mount -o vers=4.2 ...
```

### Samba AD Certificate Validation

For production, validate Samba AD certificates:

```bash
# Enable LDAPS validation in NFS mount options
mount -o sec=krb5p,krb5i 10.0.10.60:/srv/nfs/backups /mnt/nfs/backups
```

---

## Integration with orchestrator.sh

The `orchestrator.sh` backup script automatically uses NFS backups when `/mnt/nfs/backups` is available:

```bash
# orchestrator.sh (excerpt)
BACKUP_DESTINATION="${BACKUP_DESTINATION:-/mnt/nfs/backups}"

# If mounted, backups go to NFS
if mountpoint -q "$BACKUP_DESTINATION"; then
    echo "✅ NFS backup destination verified"
else
    echo "⚠️  NFS not mounted, using local backup"
    BACKUP_DESTINATION="/tmp/backups"
fi
```

---

## Security Notes

1. **Keytab Permissions**: Always `600` (root-only read)
2. **NFS Firewall**: Restrict port 2049 to trusted IPs only
3. **Audit Logging**: Monitor `/var/log/audit/audit.log` for NFS access
4. **Kerberos Ticket Lifetime**: Set to 24h (renewable for 7d)
5. **Export Permissions**: Use `/32` CIDR masks (single-host granularity)

---

## References

- **RFC 3530**: NFS v4 Protocol
- **RFC 3530bis**: NFS v4.2 Protocol (NFSv4.2, sec=krb5p)
- **Kerberos**: https://web.mit.edu/kerberos/
- **Samba AD/DC**: https://wiki.samba.org/index.php/Active_Directory_Setup
- **Linux NFS**: https://linux-nfs.org/wiki/index.php/Main_Page
