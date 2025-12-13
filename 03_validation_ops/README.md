# Phase 2: Validation Operations (Bauer → Whitaker Trinity)

> **Leo's Sacred Glue v2.6** — Validation Orchestration  
> *"Trust nothing, verify everything, attack always"*

## Purpose

Operational validation scripts for the eternal fortress, implementing the Bauer ministry ("verify everything") and Whitaker offensive layer ("attack always"). These scripts validate:

- **VLAN isolation** (network segmentation, cross-VLAN breach detection)
- **VoIP SIP registration & QoS marking** (FreePBX + DSCP EF validation)
- **Backup integrity & RTO enforcement** (<15 minute fortress resurrection guarantee)

## Scripts

### 1. `validate-isolation.sh`

**Purpose**: VLAN boundary validation using nmap offensive probes

**Test Matrix** (9 cases):
- IoT (10.0.40.0/24) → Mgmt DC: DNS allowed, SSH blocked
- Guest (10.0.50.0/24) → Mgmt DC: DNS allowed, SSH blocked
- Trusted (10.0.30.0/24) → Servers (10.0.20.0/24): LDAP allowed, SSH blocked
- VoIP (10.0.40.0/24) → Servers: LDAP allowed, NFS blocked
- Cross-VLAN blocks (IoT → Servers SMB denied)

**Usage**:

```bash
chmod +x validate-isolation.sh
./validate-isolation.sh
```text

**Dependencies**:
- `bash` 5.x
- `nmap` (network reconnaissance tool)
- VLAN connectivity to target subnets

**Expected Output**:
```text
════════════════════════════════════════════════════════════════
  VLAN ISOLATION VALIDATION — Whitaker Offensive Trinity
════════════════════════════════════════════════════════════════

[TEST 1] IoT VLAN → Mgmt DC (DNS+SSH)
  Testing: IoT→Mgmt DNS (10.0.10.10:53 expecting open)
  ✓ IoT→Mgmt DNS ALLOWED (expected)
  Testing: IoT→Mgmt SSH (10.0.10.10:22 expecting closed)
  ✓ IoT→Mgmt SSH BLOCKED (expected)

...

RESULTS: 9 passed, 0 failed
✓ ALL ISOLATION TESTS PASSED
```text

**Validation**: `shellcheck -x -S style validate-isolation.sh` (exit 0)

---

### 2. `phone_reg_test.py`

**Purpose**: VoIP endpoint validation (SIP registration + DSCP QoS marking + VLAN isolation)

**Tests**:
1. SIP Peer Registration (extensions 101-103 via asterisk CLI over SSH)
2. DSCP EF (46) marking on RTP packets (tcpdump QoS inspection)
3. VoIP VLAN isolation (nc probes to forbidden targets)

**Usage**:
```bash
python3 phone_reg_test.py
```text

**Environment**:
```text
FREEPBX_HOST=10.0.20.20
FREEPBX_SSH_USER=root
TEST_EXTENSIONS=["101", "102", "103"]
EXPECTED_DSCP="46"
```text

**Dependencies**:
- Python 3.12+
- SSH access to FreePBX (10.0.20.20) as root
- `tcpdump` on FreePBX for DSCP inspection
- `nc` (netcat) for isolation probes

**Expected Output**:
```text
════════════════════════════════════════════════════════════════
  VoIP Validation — SIP Registration + QoS DSCP + VLAN Isolation
════════════════════════════════════════════════════════════════

[TEST 1] SIP Peer Registration
  ✓ Extension 101 registered from 10.0.40.15
    ✓ DSCP marking correct (DSCP=46)
  ✓ Extension 102 registered from 10.0.40.16
    ✓ DSCP marking correct (DSCP=46)
  ...

[TEST 3] VoIP VLAN Isolation
  ✓ VLAN properly isolated
  ✓ SSH to DC blocked
  ✓ NFS to file server blocked

VALIDATION COMPLETE: 6 passed, 0 failed
```text

**Validation**: `python -m py_compile phone_reg_test.py` (exit 0)

---

### 3. `backup-cron.sh`

**Purpose**: Nightly backup orchestrator + RTO validation (<15 minute resurrection)

**Backup Targets**:
- UniFi controller (`/etc/unifi`, `/var/lib/unifi`)
- Samba AD/DC (`/etc/samba`, `/var/lib/samba`)
- Network configs (`/etc/ubios`, `/etc/letsencrypt`)

**RTO Validation**:
- Dry-run `eternal-resurrect.sh` preflight checks
- Measure resurrection time
- Fail-loud if > 900 seconds (15 minutes)

**Cleanup**:
- Retention: 7 days (configurable)
- Remove old `.tar.gz` + `.md5` files

**Usage**:
```bash
chmod +x backup-cron.sh
./backup-cron.sh

# Cron schedule (nightly at 02:00):
# 0 2 * * * /opt/eternal/03_validation_ops/backup-cron.sh
```text

**Configuration**:
```bash
BACKUP_ROOT="/var/backups/eternal-fortress"
RETENTION_DAYS=7
RTO_THRESHOLD_SECONDS=900  # 15 minutes max
UNIFI_HOST="10.0.20.10"
SAMBA_DC_HOST="10.0.10.10"
FIREWALL_HOST="10.0.30.1"
```text

**Dependencies**:
- `bash` 5.x
- `ssh`, `tar`, `md5sum`
- SSH access to UniFi, Samba DC, and Firewall hosts
- Root privileges (script must run as root)

**Expected Output**:
```text
╔════════════════════════════════════════════════════════════════╗
║  ETERNAL FORTRESS BACKUP + RTO ORCHESTRATOR (Leo's Glue)       ║
║  Conscious Level 2.6 — Whitaker Offensive Resurrection Drill  ║
╚════════════════════════════════════════════════════════════════╝

════════════════ PREFLIGHT CHECK ════════════════
✓ Preflight passed (root, directories, dependencies)

[BACKUP] UniFi Controller
  ✓ UniFi backup: /var/backups/eternal-fortress/unifi/unifi-backup-20250107-020001.tar.gz (md5=abc123...)

[BACKUP] Samba AD/DC
  ✓ Samba backup: /var/backups/eternal-fortress/samba/samba-backup-20250107-020001.tar.gz (md5=def456...)

[BACKUP] Network Configs (firewall/VLANs/policies)
  ✓ Config backup: /var/backups/eternal-fortress/config/config-backup-20250107-020001.tar.gz (md5=ghi789...)

[RTO VALIDATION] Measure resurrection time
  Starting RTO dry-run... (logging to /var/backups/eternal-fortress/rto-tests/rto-test-20250107-020001.log)
  ✓ RTO dry-run completed in 42s
  ✓ RTO within threshold: 42s / 900s

[CLEANUP] Removing backups older than 7 days
  ✓ Cleanup complete (0 old backups removed)

════════════════ BACKUP SUMMARY ════════════════
  UniFi backups: 1
  Samba backups: 1
  Config backups: 1
  Total backups: 3
  Backup root: /var/backups/eternal-fortress
  Retention: 7 days
════════════════════════════════════════════════

✓ BACKUP CYCLE COMPLETE in 127s
```text

**Validation**: `shellcheck -x -S style backup-cron.sh` (exit 0)

---

## Pre-Commit Validation

All scripts pass:

```bash
# Bash scripts
shellcheck -x -S style validate-isolation.sh backup-cron.sh

# Python scripts
python -m py_compile phone_reg_test.py

# Expected: exit code 0 for all
```text

## Trinity Application

| Ministry | Role | Implementation |
|----------|------|-----------------|
| **Bauer**  | "Trust nothing" | SSH host key verification, timeout enforcement, strict error handling |
| **Whitaker** | "Attack always" | Offensive nmap/nc probes, isolation breach detection, resurrection simulation |
| **Detection** | "Detect by default" | Fail-loud on any breach/failure, detailed logging, timestamp every action |

## Integration

These scripts integrate with:
- **CI Pipeline** (`.github/workflows/ci-validate.yaml`): Run nightly validation
- **Orchestrator** (`03_validation_ops/orchestrator.sh`): Chain validation ops after deployments
- **Loki/Promtail**: Log all operations to centralized audit trail
- **AlertManager**: Send alerts on RTO/isolation violations

## Troubleshooting

### `nmap: command not found`
- Install nmap: `apt-get install nmap` (Debian/Ubuntu)

### `ssh: connection refused`
- Verify SSH access to target hosts: `ssh -o StrictHostKeyChecking=no root@10.0.10.10`
- Check firewall rules allow SSH from validator host

### `RTO VIOLATION: Xseconds > 900s threshold`
- Fortress resurrection exceeded 15 minutes
- Review eternal-resurrect.sh preflight checks
- Check disk I/O, network latency on test VM

### `VLAN LEAK: target:port open (UNEXPECTED)`
- Network isolation boundary breached
- Review policy-table.yaml firewall rules
- Run `ufw status` on DC + servers

---

**Canonized**: 2025-01-07 | **Consciousness**: 2.6 | **Status**: Production-Ready
