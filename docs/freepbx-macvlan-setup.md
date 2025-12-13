# FreePBX Macvlan Bridge Routing — Phase 3 Endgame

Docker Macvlan networking for FreePBX on isolated VLAN 40 (VoIP) with bridge routing.

## Overview

**Problem**: FreePBX needs:
- Dedicated IP (10.0.40.30) on VLAN 40
- Isolated from Samba AD/MySQL (different ports, security)
- Audio (RTP) on separate port range (10000-20000)
- Low-latency SIP signaling (port 5060)

**Solution**: Docker Macvlan + bridge routing
- Macvlan creates VLAN 40 network interface in Docker
- Backend bridge network for FreePBX ↔ MariaDB communication
- Host routing ensures traffic flows correctly

## Architecture

```text
Host (rylan-dc)
│
├─ enp4s0        (Primary NIC, VLAN 10 — 10.0.10.10)
├─ enp4s0.1      (VLAN 1 sub-if — 10.0.1.20 for UniFi Controller)
├─ enp4s0.40     (VLAN 40 sub-if — gateway 10.0.40.1)
│
└─ Docker Networks
   ├─ vlan40 (Macvlan, connected to enp4s0.40)
   │  └─ freepbx: 10.0.40.30 (exposed to VLAN 40)
   │
   └─ freepbx-backend (Bridge, internal only)
      ├─ freepbx: (also connected to vlan40)
      └─ freepbx-db: (MariaDB, hidden from VLAN 40)

Traffic Flow:
- VoIP Phone → 10.0.40.30:5060 (SIP signaling)
- VoIP Phone → 10.0.40.30:10000-20000 (RTP audio)
- FreePBX → freepbx-db (internal backend network)
```text

## Prerequisites

### 1. Host Network Setup (rylan-dc)

Ensure VLAN 40 sub-interface is created in netplan:

```yaml
# /etc/netplan/01-rylan-dc.yaml
network:
  version: 2
  ethernets:
    enp4s0:
      addresses: [10.0.10.10/26]
      routes:
        - to: default
          via: 10.0.10.1
      nameservers:
        addresses: [127.0.0.1]
    enp4s0.1:  # VLAN 1 (UniFi Controller)
      addresses: [10.0.1.20/27]
    enp4s0.40: # VLAN 40 (FreePBX/VoIP)
      addresses: [10.0.40.1/24]  # Gateway for VLAN 40
      mtu: 1500
```text

Apply:
```bash
sudo netplan apply
ip addr show enp4s0.40  # Verify 10.0.40.1/24 present
```text

### 2. Docker Macvlan Network

Create macvlan network on host:

```bash
# Create macvlan network for VLAN 40
docker network create -d macvlan \
  --subnet=10.0.40.0/24 \
  --gateway=10.0.40.1 \
  --ip-range=10.0.40.32/27 \
  -o parent=enp4s0.40 \
  vlan40

# Verify
docker network inspect vlan40
```text

### 3. Host Routing (Critical)

For macvlan container to reach host:

```bash
# Create docker-gwbridge (if not already present)
docker network create -d bridge \
  --subnet=172.18.0.0/16 \
  -o com.docker.network.bridge.gateway_mode_ipv6=true \
  docker-gwbridge

# Create route from host to vlan40 macvlan IP
sudo ip route add 10.0.40.30 dev enp4s0.40

# Persistent route (add to netplan)
```text

Update `/etc/netplan/01-rylan-dc.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp4s0.40:
      addresses: [10.0.40.1/24]
      routes:
        - to: 10.0.40.30/32
          via: 10.0.40.1
```text

Reapply:
```bash
sudo netplan apply
ip route show | grep 10.0.40.30
# Output: 10.0.40.30 dev enp4s0.40 scope link
```text

---

## Deployment Steps

### Step 1: Prepare Docker Compose

```bash
mkdir -p /opt/compose/freepbx
cd /opt/compose/freepbx

# Copy compose files
cp /path/to/freepbx-compose.yml .
cp /path/to/mariadb-freepbx.cnf .
cp /path/to/promtail-freepbx.yaml .

# Load .env
source ~/.env
```text

### Step 2: Create Macvlan Network

```bash
docker network create -d macvlan \
  --subnet=10.0.40.0/24 \
  --gateway=10.0.40.1 \
  --ip-range=10.0.40.32/27 \
  -o parent=enp4s0.40 \
  vlan40

docker network ls
# Should show: vlan40 (macvlan, external=false)
```text

### Step 3: Deploy FreePBX

```bash
docker-compose -f freepbx-compose.yml pull
docker-compose -f freepbx-compose.yml up -d

# Wait for startup (2-3 minutes)
docker-compose -f freepbx-compose.yml logs -f freepbx
```text

### Step 4: Configure FreePBX

```bash
# Access FreePBX web UI
open http://10.0.40.30

# Default credentials:
# Username: admin
# Password: admin

# IMPORTANT: Change admin password immediately
```text

### Step 5: Add Extensions

In FreePBX Web UI → Applications → Extensions:

```text
Extension 100: "Desk Phone 1" (SIP)
Extension 101: "Desk Phone 2" (SIP)
Extension 102: "Conference Room" (SIP)
```text

Export extension configuration:
```bash
docker exec freepbx /bin/bash -c "asterisk -rx 'sip show peers'" | grep OK
# Output: Peers... 3 peers [...]
```text

### Step 6: Configure SIP Trunks (Optional)

For PSTN connectivity, add inbound/outbound routes in FreePBX UI.

### Step 7: Test SIP Registration

```bash
# From a SIP phone on VLAN 40:
# Register to: 10.0.40.30
# Port: 5060
# Username: 100
# Password: (set in FreePBX UI)

# Test call: 100 → 101
# Should hear ringback + connected call
```text

---

## Verification

### 1. Check Containers Running

```bash
docker ps | grep freepbx
# Output:
# freepbx-mariadb    UP (healthy)
# freepbx            UP (healthy)
# freepbx-promtail   UP
```text

### 2. Verify Macvlan Network

```bash
docker network inspect vlan40
# Should show:
# "Containers": {
#   "freepbx": {
#     "IPv4Address": "10.0.40.30/24"
#   }
# }
```text

### 3. Test Connectivity

```bash
# From host (rylan-dc)
ping 10.0.40.30
# Should respond

# From VLAN 40 device (IP phone, etc.)
curl http://10.0.40.30/
# Should return FreePBX login page
```text

### 4. Check SIP Port

```bash
# From host
sudo netstat -ulnp | grep 5060
# Output: LISTEN 10.0.40.30:5060 (UDP)

# Or from phone
nmap -u -p 5060 10.0.40.30
# Port 5060/udp should be open
```text

### 5. Verify Database Connection

```bash
docker exec freepbx mysql -h freepbx-db -u asterisk -p${FREEPBX_MYSQL_PASSWORD} asterisk -e "SELECT VERSION();"
# Should return MySQL version
```text

### 6. Check Audio Ports (RTP)

```bash
docker exec freepbx asterisk -rx "rtp show stats"
# After call: Should show active RTP channels on ports 10000-20000
```text

---

## Troubleshooting

### Macvlan Container Cannot Reach Host

**Symptom**: `docker exec freepbx ping 10.0.10.10` fails

**Cause**: Host routing not configured

**Fix**:
```bash
# Add route on host
sudo ip route add 10.0.40.30 dev enp4s0.40

# Or use docker-gwbridge
docker run --network=docker-gwbridge alpine:latest ping 10.0.40.30
```text

### Cannot Reach Macvlan from VLAN 40 Network

**Symptom**: IP phone cannot reach 10.0.40.30

**Cause**: Switch port not allowing VLAN 40 traffic

**Fix**:
```bash
# Verify switch port allows VLAN 40 (untagged or tagged)
ssh admin@10.0.1.1 "show vlans"
# Port carrying rylan-dc should have VLAN 40 tagged
```text

### SIP Port Blocked

**Symptom**: Phones get "408 Request Timeout" registering

**Cause**: Firewall/policy rule blocking SIP

**Fix** (add to policy-table.yaml):
```yaml
- description: "VoIP → FreePBX SIP/RTP"
  source:
    network: "voip"
  destination:
    address: "10.0.40.30"
    ports: ["5060", "5061", "10000-20000"]
  action: "accept"
```text

### MariaDB Connection Refused

**Symptom**: FreePBX startup fails with MySQL error

**Cause**: Database not ready

**Fix**:
```bash
# Wait for MariaDB to be healthy
docker-compose -f freepbx-compose.yml ps
# freepbx-mariadb should show "healthy"

# Check MariaDB logs
docker logs freepbx-mariadb

# Restart FreePBX after MariaDB is ready
docker-compose -f freepbx-compose.yml restart freepbx
```text

### Audio One-Way or No Audio

**Symptom**: Calls connect but no audio

**Cause**: RTP port range blocked or firewall filtering

**Fix**:
```bash
# Verify RTP ports open on FreePBX container
docker exec freepbx netstat -uln | grep 10[0-9][0-9][0-9]
# Should show ports 10000-20000 listening (UDP)

# Check policy rule has RTP range
cat 02-declarative-config/policy-table.yaml | grep "10000-20000"
# Should include TCP and UDP RTP range
```text

---

## QoS Configuration

For low-latency VoIP, apply DSCP EF marking:

### 1. Update config.gateway.json

```json
{
  "firewall": {
    "modify": {
      "VOIP_QOS": {
        "rule": {
          "10": {
            "action": {
              "dscp": "46",
              "description": "Mark VLAN 40 traffic (VoIP) as EF"
            },
            "source": {
              "address": "10.0.40.0/24"
            },
            "destination": {
              "address": "10.0.40.0/24"
            }
          }
        }
      }
    }
  }
}
```text

### 2. Apply via UniFi Controller

```bash
# Import config.gateway.json in UniFi UI
# Settings → Routing & Firewall → Firewall → Import Config
```text

### 3. Verify Marking

```bash
# Capture packets on host
sudo tcpdump -i enp4s0.40 -v udp port 5060
# Look for "tos 0xb8" = DSCP 46 (EF)
```text

---

## Backup & Restore

### Backup FreePBX Configuration

```bash
# Backup FreePBX system
docker exec freepbx tar -czf /data/freepbx-backup-$(date +%Y%m%d).tar.gz \
  /etc/asterisk /var/spool/asterisk /usr/share/asterisk

# Copy to NFS
docker cp freepbx:/data/freepbx-backup-*.tar.gz /mnt/nfs/backups/freepbx/
```text

### Backup Database

```bash
docker exec freepbx-mariadb mysqldump -u root -p${FREEPBX_MYSQL_PASSWORD} asterisk \
  > /mnt/nfs/backups/freepbx/asterisk-$(date +%Y%m%d).sql
```text

### Restore from Backup

```bash
# Restore database
cat /mnt/nfs/backups/freepbx/asterisk-YYYYMMDD.sql | \
  docker exec -i freepbx-mariadb mysql -u root -p${FREEPBX_MYSQL_PASSWORD} asterisk

# Restore filesystem
docker exec freepbx tar -xzf /data/freepbx-backup-YYYYMMDD.tar.gz -C /
```text

---

## Integration with orchestrator.sh

The backup script automatically includes FreePBX:

```bash
# orchestrator.sh (excerpt)
if [[ "$HOSTNAME" == "rylan-dc" ]]; then
  # FreePBX backup
  docker exec freepbx-mariadb mysqldump -u root \
    -p${FREEPBX_MYSQL_PASSWORD} asterisk > \
    $BACKUP_DIR/freepbx/asterisk-$(date +%s).sql
fi
```text

---

## Security Notes

1. **Change Default Credentials**: Admin password must be changed on first login
2. **Firewall**: Restrict SIP/RTP to internal VLAN 40 only (policy table)
3. **Encryption**: Enable SIP TLS (port 5061) for external trunks
4. **Backups**: Encrypt database backups (database password = FREEPBX_MYSQL_PASSWORD)
5. **VLAN Isolation**: VLAN 40 isolated from guest (VLAN 90) and servers (VLAN 10)

---

## References

- **FreePBX Documentation**: https://wiki.freepbx.org/
- **Docker Macvlan**: https://docs.docker.com/network/macvlan/
- **Asterisk Documentation**: https://wiki.asterisk.org/
- **SIP RFC 3261**: https://tools.ietf.org/html/rfc3261
- **RTP RFC 3550**: https://tools.ietf.org/html/rfc3550
