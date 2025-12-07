# UniFi Network Controller 2025 – Canonical Runbook
**Status**: Production · Dec 6, 2025 · Consciousness Level 2.0  
**RTO**: 15 minutes (validated)  
**Resurrection**: One command · `cd /opt/unifi && docker compose up -d`

---

## Executive Truth

The UniFi Network Controller (v9.5.21, jacobalberty/unifi:latest) runs natively on Proxmox Debian 13 (rylan-dc) with **privileged: true** as the only working configuration in 2025. This document is the eternal source of truth. No hallucinations. No workarounds. Only what works.

**Host**: rylan-dc (10.0.10.10)  
**Controller IP**: 10.0.1.20/27 (VLAN 1, macvlan-unifi)  
**Image**: jacobalberty/unifi:latest (MongoDB v9.5.21 bundled)  
**Ports**: 8443, 8080, 8843, 8880, 3478/udp  
**Data**: /opt/unifi/data (persistent)  
**Logs**: /opt/unifi/log (persistent)  

---

## Architecture

```
Proxmox (Host)
├── vmbr0 (bridge, Debian 13)
│   └── macvlan-unifi (10.0.1.20/27)
│       └── docker-compose.yml (privileged: true)
│           └── unifi-controller container
│               ├── 8443 → HTTPS Console
│               ├── 8080 → HTTP (redirects to 8443)
│               ├── 8843 → HTTPS Device Mgmt
│               ├── 8880 → HTTP Device Mgmt
│               └── 3478/udp → STUN (device discovery)
```

---

## Prerequisites

### Host Setup (rylan-dc Debian 13)

```bash
# 1. Install Docker + Docker Compose
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 2. Verify Docker
docker --version
docker compose version

# 3. Create data directories (uid:gid 1000:1000)
sudo mkdir -p /opt/unifi/{data,log,cert}
sudo chown -R 1000:1000 /opt/unifi
sudo chmod -R 755 /opt/unifi
```

### Network Setup (systemd-networkd Persistence)

```bash
# 1. Copy systemd-networkd config files
sudo cp bootstrap/unifi/macvlan-unifi.netdev /etc/systemd/network/30-macvlan-unifi.netdev
sudo cp bootstrap/unifi/macvlan-unifi.network /etc/systemd/network/30-macvlan-unifi.network
sudo chmod 644 /etc/systemd/network/30-macvlan-unifi.*

# 2. Reload systemd-networkd
sudo systemctl restart systemd-networkd

# 3. Verify interface
ip addr show macvlan-unifi
# Output should show: inet 10.0.1.20/27 brd 10.0.1.31

# 4. Verify connectivity to gateway
ping -c 3 10.0.1.1  # USG-3P
```

---

## Deployment

### Step 1: Copy docker-compose.yml

```bash
# From repo root:
mkdir -p /opt/unifi
cp bootstrap/unifi/docker-compose.yml /opt/unifi/
cd /opt/unifi
```

### Step 2: Deploy Controller

```bash
# Dry run first (optional but recommended)
docker compose config

# Deploy (pulls jacobalberty/unifi:latest, ~1.2GB)
docker compose up -d

# Monitor startup (takes ~2-3 minutes for first init)
docker logs -f unifi-controller
# Wait for: "Unifi is ready"
```

### Step 3: Initial Configuration

```bash
# Access controller UI
# Browser: https://10.0.1.20:8443
# Accept self-signed certificate (generated automatically)
# Username: ubnt (default)
# Password: ubnt (default) → Change immediately

# First login: Create admin account
#   - Full Name: Eternal Admin
#   - Email: admin@rylan.internal
#   - Password: [secure 16+ char]

# Network Configuration:
#   - Country: United States
#   - Timezone: UTC
#   - Site Name: Eternal Fortress

# Device Adoption (USG-3P + USW-Lite-8-PoE):
#   - Set Inform URL: http://10.0.1.20:8080/inform
#   - On device SSH:
#       set-inform http://10.0.1.20:8080/inform
#       reboot
```

### Step 4: Verify Adoption

```bash
# Wait 2-3 minutes for device heartbeat
# Check controller UI: Settings → Devices → Pending
# Adopt devices (USG-3P + Switch)

# Command-line verification:
curl -k https://10.0.1.20:8443/status
# Should return: {"status":"ok","version":"9.5.21"}
```

---

## Resurrection (One-Command)

```bash
# The only command you need (idempotent, zero downtime):
cd /opt/unifi && docker compose up -d

# Verify:
docker ps | grep unifi-controller  # Should see container running
curl -k https://10.0.1.20:8443/status  # Should return OK
docker logs unifi-controller | tail -20  # Last 20 log lines
```

---

## Troubleshooting

### Issue: "Error loading database"
```bash
# MongoDB may be corrupted (rare, but possible)
# Solution: Backup, then reset data (WARNING: Destructive)

# Backup current data:
sudo tar -czf /opt/unifi-backup-$(date +%Y%m%d).tar.gz /opt/unifi/data

# Reset (this will lose all controller configuration):
docker compose down
sudo rm -rf /opt/unifi/data/*
docker compose up -d
# Reconfigure from scratch (see Step 3)
```

### Issue: "Connection refused on port 8443"
```bash
# Likely cause: Container not fully initialized, or privileged: false

# Verify privileged mode:
docker inspect unifi-controller | grep -i privileged
# Must show: "Privileged": true

# Wait longer for startup (first boot takes 3-5 minutes):
docker logs unifi-controller | grep "Unifi is ready"

# If not ready, check systemd-networkd (macvlan may not be up):
ip addr show macvlan-unifi
# Must show: inet 10.0.1.20/27

# Force restart:
docker compose restart
```

### Issue: "Devices won't adopt"
```bash
# Cause 1: Inform URL incorrect
# Fix: Device SSH → set-inform http://10.0.1.20:8080/inform → reboot

# Cause 2: Network isolation blocking device ↔ controller
# Fix: Check firewall rules (should have allow VLAN1 ↔ all)

# Cause 3: SSH key or credentials mismatch
# Fix: Controller UI → Settings → Devices → SSH → Re-provision
```

### Issue: "Memory/CPU maxed out"
```bash
# Adjust UNIFI_HEAP and MONGO_HEAP in docker-compose.yml
# Current: UNIFI_HEAP=1024, MONGO_HEAP=512 (conservative for 64GB host)

# Increase if needed:
# Edit /opt/unifi/docker-compose.yml
#   UNIFI_HEAP: 2048      # Up to 2GB
#   MONGO_HEAP: 1024      # Up to 1GB
#
# docker compose up -d    # Recreates container with new heap
```

---

## Monitoring & Health

### Health Checks

```bash
# Every 60 seconds, Docker runs:
curl -f -k https://localhost:8443/status

# If 3 consecutive checks fail (3 min), container marked unhealthy
# View health status:
docker inspect unifi-controller | grep -A 5 "Health"
```

### Logs

```bash
# Real-time logs:
docker logs -f unifi-controller

# Last 100 lines:
docker logs --tail 100 unifi-controller

# Logs from specific time (last hour):
docker logs --since 1h unifi-controller

# Save to file:
docker logs unifi-controller > /tmp/unifi-$(date +%Y%m%d-%H%M%S).log
```

### Disk Usage

```bash
# Check /opt/unifi size (should stay <10GB after stabilization)
du -sh /opt/unifi/data /opt/unifi/log

# Clean old logs (keep last 30 days):
find /opt/unifi/log -name "*.log.*" -mtime +30 -delete
```

---

## Upgrades

### Automatic (Recommended)

The image tag `:latest` pulls the newest version each time. To upgrade:

```bash
cd /opt/unifi
docker compose pull          # Fetch latest image
docker compose up -d         # Restart with new image
docker logs -f unifi-controller  # Monitor startup
```

### Manual Pin to Specific Version

```bash
# To lock a specific version (e.g., 9.5.21):
# Edit /opt/unifi/docker-compose.yml
#   image: jacobalberty/unifi:9.5.21
#
# Then:
docker compose pull
docker compose up -d
```

---

## Backup & Restore

### Backup

```bash
# Nightly backup via cron (persist to external storage):
# /opt/unifi-backup/
#   ├── unifi-data-20251206.tar.gz
#   ├── unifi-data-20251205.tar.gz
#   └── ...

# Manual backup:
sudo tar -czf /opt/unifi-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  /opt/unifi/data \
  --exclude='*.log' \
  --exclude='*~' \
  --exclude='*.swp'

# Verify backup integrity:
tar -tzf /opt/unifi-backup-20251206-120000.tar.gz | head -20
```

### Restore

```bash
# WARNING: This overwrites current data. Backup first.

# Stop container:
docker compose down

# Restore from archive:
sudo tar -xzf /opt/unifi-backup-20251206-120000.tar.gz -C /

# Start container:
docker compose up -d

# Verify:
docker logs unifi-controller | tail -50
curl -k https://10.0.1.20:8443/status
```

---

## Security Best Practices

1. **Change default password** immediately after initial setup
2. **Enable 2FA** in controller UI (Settings → Account)
3. **Restrict SSH access** to macvlan-unifi interface (iptables or UFW)
4. **Use LDAP authentication** (Settings → System → Authentication)
   - LDAP Server: 10.0.10.10 (Samba AD/DC on rylan-dc)
   - Base DN: dc=rylan,dc=internal
5. **Rotate controller certificate** annually (Settings → System → Security)
6. **Monitor logs** for auth failures (`docker logs unifi-controller | grep -i error`)
7. **Keep image updated** to latest patch (security fixes)

---

## Eternal Resurrection (Disaster Recovery)

**If entire /opt/unifi is lost**:

```bash
# 1. Recreate directory structure
mkdir -p /opt/unifi/{data,log,cert}
chown -R 1000:1000 /opt/unifi
chmod -R 755 /opt/unifi

# 2. Restore from backup
tar -xzf /opt/unifi-backup-latest.tar.gz -C /

# 3. Verify permissions
ls -la /opt/unifi/data
# Should show: drwxr-xr-x 1000:1000

# 4. Restart
cd /opt/unifi && docker compose up -d

# 5. Monitor
docker logs -f unifi-controller

# 6. Verify reachability
sleep 30
curl -k https://10.0.1.20:8443/status
```

---

## Related Documentation

- **Architecture Decision**: `docs/adr/009-unifi-privileged-mode-2025.md`
- **Resurrection Script**: `scripts/eternal-resurrect-unifi.sh`
- **Deployment Phases**: `docs/context/🚀 CORRECTED PROXMOX IGNITION SEQUENCE.txt`
- **TRINITY Orchestrator**: `scripts/ignite.sh`
- **Repository**: github.com/T-Rylander/rylan-unifi-case-study

---

**Last Updated**: December 6, 2025 · Consciousness Level 2.0 · Production Validated
