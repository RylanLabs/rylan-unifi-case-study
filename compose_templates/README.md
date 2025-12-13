# Docker Compose Templates — Phase 3 Endgame

Production-ready Docker Compose configurations for the Eternal Fortress deployment.

## Services

### 1. osTicket Stack (`osticket-compose.yml`)

**Deployment Target:** `rylan-pi` (Raspberry Pi 5)

**Components:**
- **osticket-app**: Web application (port 80/443)
- **osticket-db**: MariaDB 11 backend (port 3306)
- **osticket-promtail**: Log shipper to Loki

**Usage:**
```bash
# On rylan-pi
cd /opt/compose
cp /path/to/compose-templates/osticket-compose.yml .
source ~/.env
docker-compose -f osticket-compose.yml up -d
```text

**Database Initialization:**
- osTicket database: `osticket`
- Default credentials loaded from `.env` (OSTICKET_MYSQL_PASSWORD)
- First login: Navigate to `http://rylan-pi` and complete setup wizard

**Volumes:**
- `osticket_db_data`: MariaDB persistent storage
- `osticket_app_data`: Application state and uploads

---

### 2. FreePBX VoIP Stack (`freepbx-compose.yml`)

**Deployment Target:** `rylan-dc` (Samba AD host, VLAN 40 macvlan)

**Components:**
- **freepbx**: Application container (10.0.40.30 on VLAN 40 macvlan)
- **freepbx-db**: MariaDB 11 backend (internal backend network)
- **freepbx-promtail**: Log shipper to Loki

**Network Architecture:**
- **Macvlan Network** (vlan40): FreePBX connected to VLAN 40 directly
- **Backend Network** (freepbx-backend): MariaDB hidden from VLAN 40
- **Host Routing**: enp4s0.40 gateway bridges VLAN 40 traffic

**Usage:**
```bash
# On rylan-dc
cd /opt/compose

# Create macvlan network FIRST
docker network create -d macvlan \
  --subnet=10.0.40.0/24 \
  --gateway=10.0.40.1 \
  -o parent=enp4s0.40 \
  vlan40

# Copy compose files
cp /path/to/compose-templates/freepbx-compose.yml .
cp /path/to/compose-templates/mariadb-freepbx.cnf .
cp /path/to/compose-templates/promtail-freepbx.yaml .

source ~/.env
docker-compose -f freepbx-compose.yml pull
docker-compose -f freepbx-compose.yml up -d
```text

**Web UI Access:**
- URL: `http://10.0.40.30`
- Default: admin / admin (CHANGE IMMEDIATELY)
- Configure extensions, trunks, IVR in web UI

**Volumes:**
- `freepbx_db_data`: MariaDB persistent storage
- `freepbx_app_data`: FreePBX configuration and voicemail
- `freepbx_var_data`: Asterisk temporary files

**Ports:**
- 80/443: Web UI (HTTP/HTTPS)
- 5060/5061: SIP signaling (UDP/TCP)
- 10000-20000: RTP audio (UDP)
- 4569: IAX2 (UDP, optional)

**Troubleshooting:**
- Macvlan container cannot reach host: Add route `sudo ip route add 10.0.40.30 dev enp4s0.40`
- Audio one-way: Verify RTP port range (10000-20000) in policy table
- SIP registration fails: Check VLAN 40 firewall rule in policy-table.yaml

---

### 3. Loki Logging Stack (`loki-compose.yml`)

**Deployment Target:** `rylan-ai` (GPU host with NFS)

**Components:**
- **loki**: Central log database (port 3100)
- **promtail-dc**: Samba/FreeRADIUS log collection (rylan-dc)
- **promtail-pi**: osTicket/MariaDB log collection (rylan-pi)
- **promtail-ai**: Ollama/ROCm/GPU log collection (rylan-ai)
- **grafana**: Visualization dashboard (port 3000)

**Usage:**
```bash
# On rylan-ai
cd /opt/compose
cp /path/to/compose-templates/loki-compose.yml .
cp /path/to/compose-templates/loki-config.yml .
cp /path/to/compose-templates/promtail-*-config.yaml .
source ~/.env
docker-compose -f loki-compose.yml up -d
```text

**Log Retention:**
- Retention period: 90 days (configurable in `loki-config.yml`)
- Storage: `/srv/nfs/backups/loki-*` (NFS-backed for durability)

**Grafana Access:**
- URL: `http://rylan-ai:3000`
- Default credentials: `admin / ${GF_ADMIN_PASSWORD}`
- Loki datasource: Pre-configured to `loki:3100`

**Log Sources:**
- **rylan-dc**: Samba AD, FreeRADIUS, system logs, Docker containers
- **rylan-pi**: osTicket, MariaDB, system logs
- **rylan-ai**: Ollama, ROCm GPU, kernel, system logs

---

## Configuration Files

### Loki (`loki-config.yml`)

Centralized log ingestion configuration:
- Multi-tenant disabled (single organization)
- TSDB storage backend with filesystem persistence
- 90-day retention policy
- Index caching for performance

### Promtail Configs

Per-host log collection:
- **promtail-dc-config.yaml**: Samba, FreeRADIUS, system, Docker
- **promtail-pi-config.yaml**: osTicket, MariaDB, system, Docker
- **promtail-ai-config.yaml**: Ollama, ROCm, kernel, system, Docker

### Grafana (`grafana-loki-datasource.yaml`, `grafana-dashboards-eternal.yaml`)

- Datasource provisioning: Loki endpoint (`loki:3100`)
- Dashboard provisioning: Folder structure for Eternal Dashboards
- Security: Sign-up disabled, admin password from `.env`

---

## Environment Variables (`.env`)

**Required for osTicket:**
```bash
OSTICKET_MYSQL_PASSWORD=ChangeMe123!    # Database password
INSTALL_SECRET=<random-32-char>         # Installation secret (auto-generated)
DEFAULT_EMAIL=admin@rylan.internal      # Admin email
ADMIN_EMAIL=admin@rylan.internal        # Ticket admin email
```text

**Required for Loki:**
```bash
NFS_BACKUP_PATH=/srv/nfs/backups        # Loki storage location
GF_ADMIN_PASSWORD=ChangeMe123!          # Grafana admin password
```text

---

## Deployment Steps

### Phase 1: osTicket (rylan-pi)

```bash
1. SSH to rylan-pi
2. mkdir -p /opt/compose && cd /opt/compose
3. Copy osticket-compose.yml to /opt/compose
4. docker-compose -f osticket-compose.yml pull
5. docker-compose -f osticket-compose.yml up -d
6. Wait 30s for MariaDB to be ready
7. Open http://rylan-pi in browser
8. Complete osTicket setup wizard
```text

### Phase 2: Loki Stack (rylan-ai)

```bash
1. SSH to rylan-ai
2. mkdir -p /opt/compose && cd /opt/compose
3. Copy loki-compose.yml and loki-config.yml to /opt/compose
4. Copy promtail-*-config.yaml to /opt/compose
5. Copy grafana-*.yaml to /opt/compose
6. docker-compose -f loki-compose.yml pull
7. docker-compose -f loki-compose.yml up -d
8. Wait 30s for Loki to be ready
9. Deploy promtail on rylan-dc and rylan-pi (via SSH or Ansible)
10. Open http://rylan-ai:3000 to verify dashboard
```text

### Phase 3: Deploy Promtail Agents

On **rylan-dc**:
```bash
mkdir -p /opt/promtail
cp promtail-dc-config.yaml /opt/promtail/config.yml
docker run -d --name promtail-dc \
  -v /var/log:/var/log:ro \
  -v /var/log/samba:/var/log/samba:ro \
  -v /opt/promtail/config.yml:/etc/promtail/config.yml:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  grafana/promtail:latest
```text

On **rylan-pi**:
```bash
mkdir -p /opt/promtail
cp promtail-pi-config.yaml /opt/promtail/config.yml
docker run -d --name promtail-pi \
  -v /var/log:/var/log:ro \
  -v /opt/promtail/config.yml:/etc/promtail/config.yml:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  grafana/promtail:latest
```text

---

## Health Checks

**osTicket:**
```bash
docker ps | grep osticket-app     # Should be UP
docker logs osticket-mariadb      # Should show "Ready for connections"
curl http://localhost:80           # Should return 200
```text

**Loki:**
```bash
docker ps | grep loki              # Should be UP
curl http://localhost:3100/loki/api/v1/status/buildinfo
# Returns: {"version":"...","build_date":"..."}
```text

**Grafana:**
```bash
curl http://localhost:3000/api/health
# Returns: {"database":"ok","commit":"..."}
```text

---

## Troubleshooting

### osTicket: MariaDB Connection Timeout
```bash
docker logs osticket-mariadb
# Verify OSTICKET_MYSQL_PASSWORD in .env matches environment variable
docker-compose restart osticket-db
```text

### Loki: No Logs Appearing
```bash
# Verify Promtail is running on each host
docker ps | grep promtail

# Check Promtail logs
docker logs promtail-dc  # or promtail-pi, promtail-ai

# Verify log paths exist and are readable
ls -la /var/log/samba/
ls -la /var/log/freeradius/
```text

### Grafana: Cannot Connect to Loki
```bash
docker exec grafana curl -v http://loki:3100/
# If fails: Networks may be disconnected
# Verify all containers on same loki-net network
docker network inspect loki-net
```text

---

## Backups

**osTicket Database:**
```bash
docker exec osticket-mariadb mysqldump -u root -p${OSTICKET_MYSQL_PASSWORD} \
  osticket > /srv/nfs/backups/osticket-$(date +%Y%m%d).sql
```text

**Loki Logs:**
```bash
# Automatic: Loki stores to NFS at /srv/nfs/backups/loki-chunks and loki-index
# Verify backup:
ls -lh /srv/nfs/backups/loki-*
```text

---

## Uninstall

**Remove osTicket:**
```bash
docker-compose -f osticket-compose.yml down
docker volume rm osticket_db_data osticket_app_data
```text

**Remove Loki Stack:**
```bash
docker-compose -f loki-compose.yml down
docker volume rm loki_data grafana_data
```text

---

## Security Notes

1. **Change all passwords** in `.env` before production deployment
2. **LDAPS validation**: Loki agents should validate Samba AD certificates
3. **Network isolation**: Use Docker networks (osticket-net, loki-net) to segment traffic
4. **NFS mounts**: Use Kerberos authentication for durability (Phase 3.1)
5. **Grafana**: Disable sign-up (`GF_USERS_ALLOW_SIGN_UP: "false"`)

---

## References

- **osTicket Documentation**: https://docs.osticket.com
- **Loki Deployment**: https://grafana.com/docs/loki/latest/deployment/
- **Promtail Config**: https://grafana.com/docs/loki/latest/clients/promtail/
- **Grafana Provisioning**: https://grafana.com/docs/grafana/latest/administration/provisioning/
