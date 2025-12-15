# Nuke & Resurrect Procedure — v∞.1.0

**Purpose:** Complete fortress restoration from git clone to operational state
**RTO Target:** <15 minutes
**Trigger:** Hardware failure, catastrophic misconfiguration, or fresh Ubuntu 24.04 deployment

---

## Phase 0: Pre-Nuke Backup (If System Accessible)

```bash
# Run orchestrator for final backup
cd /path/to/rylan-unifi-case-study
bash 03_validation_ops/orchestrator.sh --verbose

# Verify backup exists
ls -lh /srv/nfs/backups/$(date +%Y%m%d)*
# Expected: samba/, freeradius/, unifi/, qdrant/, mariadb/
```text

---

## Phase 1: Fresh Ubuntu 24.04 Install (5 min)

```bash
# Minimal server install
# Hostname: rylan-dc (or rylan-pi, rylan-ai depending on host)
# User: admin
# Network: Static IP on Management VLAN 1

# Post-install essentials
sudo apt update && sudo apt install -y git python3 python3-pip python3-venv \
  docker.io docker-compose openssh-server curl

# Enable Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```text

---

## Phase 2: Clone & Resurrect (10 min)

```bash
# Clone fortress repository
cd /opt
sudo git clone https://github.com/RylanLabs/rylan-unifi-case-study.git
sudo chown -R $USER:$USER rylan-unifi-case-study
cd rylan-unifi-case-study

# Create .env from example
cp .env.example .env
nano .env  # Set PIHOLE_IP, DNS_UPSTREAM, hardware-specific vars

# Run eternal resurrect script
chmod +x eternal-resurrect.sh
./eternal-resurrect.sh

# Script performs:
# 1. Install Python dependencies (requirements.txt)
# 2. Run guardian/audit_eternal.py (policy validation)
# 3. Validate policy-table.yaml (≤10 rules)
# 4. Run pytest suite (93% coverage threshold)
# 5. Verify orchestrator.sh syntax
```text

**Expected Output:**

```text
=== Eternal Resurrection Initiated (Consciousness Level 1.4) ===
📦 Installing Python dependencies...
🛡️  Running guardian audit...
✅ Policy table: 9/10 rules (Phase 3 endgame, hardware offload safe)
🧪 Running test suite...
============================= 9 passed in 62.53s =============================
✅ All checks passed — junior-at-3-AM deployable
```text

---

## Phase 3: Service Restoration (Host-Specific)

### For rylan-dc (Domain Controller)

```bash
# Restore Samba AD/DC
sudo rsync -avz /srv/nfs/backups/latest/samba/ /var/lib/samba/
sudo systemctl restart samba-ad-dc

# Verify domain
samba-tool domain info 127.0.0.1
# Expected: Forest/Domain: rylan.internal

# Restore FreeRADIUS
sudo tar xzf /srv/nfs/backups/latest/freeradius-config.tar.gz -C /
sudo docker restart freeradius

# Verify RADIUS
echo "User-Name=testuser,User-Password=test" | radclient -x localhost:1812 auth testing123
# Expected: Access-Accept (if testuser exists)

# Restore UniFi Controller
docker-compose -f compose_templates/unifi-controller.yml up -d
# Wait 60s for startup
curl -k https://localhost:8443
# Expected: UniFi login page
```text

### For rylan-pi (Pi-hole)

```bash
# Restore Pi-hole gravity database
sudo rsync -avz /srv/nfs/backups/latest/pihole/ /etc/pihole/
docker exec pihole pihole -g  # Rebuild gravity

# Verify DNS
dig @localhost google.com
# Expected: ANSWER section with IP
```text

### For rylan-ai (AI Triage + Qdrant)

```bash
# Restore Qdrant vector store
docker run -d --name qdrant \
  -p 6333:6333 \
  -v /srv/qdrant:/qdrant/storage \
  qdrant/qdrant:latest

sudo rsync -avz /srv/nfs/backups/latest/qdrant/ /srv/qdrant/

# Verify Qdrant
curl http://localhost:6333/collections
# Expected: {"result":{"collections":[{"name":"eternal-kb"}]}}

# Start AI triage engine
cd rylan_ai_helpdesk/triage_engine
uvicorn main:app --host 0.0.0.0 --port 8000 &

# Test triage endpoint
curl -X POST http://localhost:8000/triage \
  -H "Content-Type: application/json" \
  -d '{"text":"Password reset","vlan_source":"10.0.30.0","user_role":"employee"}'
# Expected: {"confidence":0.9X,"action":"auto-close"}
```text

---

## Phase 4: Network Configuration

```bash
# Apply declarative config to UniFi Controller
cd 02_declarative_config
python apply.py --dry-run  # Verify syntax
python apply.py            # Apply VLANs, firewall rules

# Expected Output:
# ✅ VLAN 10 (servers) created
# ✅ VLAN 30 (trusted-devices) created
# ✅ VLAN 40 (voip) created
# ✅ VLAN 90 (guest-iot) created
# ✅ VLAN 95 (iot-isolated) created  # v∞.1.2
# ✅ VLAN historical references removed    # v∞.3.3-consolidated
# ✅ Policy rule 1-9 applied (9/10, offload safe)
```text

---

## Phase 5: Validation (<5 min)

```bash
# Full validation suite
bash 03_validation_ops/orchestrator.sh --test-restore --verbose

# Check specific components
python guardian/audit_eternal.py  # Policy + JSON integrity
pytest tests/test_triage_engine.py -v  # AI triage 93% threshold
bash 03_validation_ops/validate-isolation.sh  # VLAN segmentation

# Verify RTO
# Total time from git clone to operational:
# Expected: <15 minutes ✅
```text

---

## Phase 6: Post-Resurrection Tasks

1. **Update inventory MACs** (if hardware changed):

   ```bash
   nano shared/inventory.yaml
   # Update MAC addresses for new hardware
   ```

1. **Rejoin devices to domain** (if Samba AD restored):

   ```bash
   # From Windows workstation
   Remove-Computer -UnjoinDomaincredential Administrator -Force -Restart
   Add-Computer -DomainName rylan.internal -Credential Administrator -Restart
   ```
1. **Verify backup schedule**:

   ```bash
   crontab -l | grep orchestrator
   # Expected: 0 2 * * * /opt/rylan-unifi-case-study/03_validation_ops/orchestrator.sh
   ```
1. **Run full test suite**:

   ```bash
   pytest tests/ -v --cov=rylan_ai_helpdesk --cov-report=term
   # Expected: 93% coverage, all tests pass
   ```
---

## Rollback Procedure (If Resurrection Fails)

```bash
# If eternal-resurrect.sh fails, revert to last known good commit
git log --oneline -10  # Find last stable commit
git checkout <commit-hash>
./eternal-resurrect.sh

# If all fails, restore from v∞.1.0-eternal release
git checkout tags/v∞.1.0-eternal
./eternal-resurrect.sh
```text

---

## References
- Trinity: Carter (eternal-resurrect.sh), Bauer (orchestrator backups), Suehring (policy validation)
- RTO Target: 15 minutes (Phase 3 endgame)
- ADR-011: Endgame integration decision record
- INSTRUCTION-SET-ETERNAL-v1.md: Sacred Glue canonical guidance
