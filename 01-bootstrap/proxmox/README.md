# Proxmox VE 8.2 Bare-Metal Ignition Script

Production-grade fortress deployment for Proxmox VE 8.2 on Z390 hardware. Transforms fresh bare-metal into a fully operational, security-hardened virtualization host in **<15 minutes**.

## Overview

### Problem Statement

Traditional Proxmox deployment is **45–90 minutes** of manual installation:
- 5–10 min: ISO boot + installer UI
- 15–20 min: Disk partitioning
- 10–15 min: Network configuration
- 10–15 min: SSH hardening & tooling
- 5–10 min: Repository setup

**Target**: Reduce RTO to **<15 minutes** with automated, auditable scripts.

### Solution Architecture

```
Fresh Hardware
    ↓
[5 min] Boot Proxmox ISO + Installer
    ↓
[<15 min] Run proxmox-ignite.sh
    ├── Phase 0: Validation (prerequisites)
    ├── Phase 1: Network Configuration (Suehring)
    ├── Phase 2: SSH Hardening (Bauer + Carter)
    ├── Phase 3: Tooling Bootstrap (Python, git, nmap)
    ├── Phase 4: Repository Sync
    ├── Phase 5: Fortress Resurrection (eternal-resurrect.sh)
    └── Phase 6: Security Validation (Whitaker offensive)
    ↓
Operational Fortress (100% green, key-only SSH, hardened)
```

## T3-ETERNAL Compliance

This script adheres to the sacred trinity:

| Framework | Principle | Implementation |
|-----------|-----------|-----------------|
| **Barrett** | Unix Zen: Small, verifiable, fail-loud | <500 lines bash, `set -euo pipefail`, atomic functions |
| **Hellodeolu** | Outcomes: 15-min RTO, junior-deployable | Single command execution, detailed logging, no decisions |
| **Whitaker** | Offensive: Security-first, pentest-hardened | nmap scans, SSH key-only, no password auth |
| **Carter** | Identity: AD/DNS-ready domain infrastructure | SSH ed25519 key injection, hostname resolution |
| **Bauer** | Paranoia: Zero passwords, hardened services | Prohibit password auth, key-only root, strong ciphers |
| **Suehring** | Network: VLAN-aware, hardware-offload safe | Static IP, gateway routing, DNS configured |

## Prerequisites

### Hardware Requirements
- **CPU**: Modern x86-64 (Intel Z390 or AMD Ryzen 3000+)
- **RAM**: ≥32 GB (recommended ≥64 GB)
- **Storage**: ≥250 GB NVMe SSD (hardware tested with Samsung 970 EVO Plus)
- **Network**: 1 Gbps Ethernet (or higher)

### Software Requirements
- **OS**: Proxmox VE 8.2 installed and booted
- **User**: Root or sudo access
- **Network**: Static IP assignment capability
- **Connectivity**: Network access to GitHub (for repository clone)

### SSH Key Prerequisites
- **Key Type**: ed25519 or RSA (ed25519 recommended)
- **Format**: OpenSSH public key (e.g., `ssh-ed25519 AAAA...`)
- **File**: Readable by root (e.g., `~/.ssh/id_ed25519.pub`)

**Generate SSH key** (if not already present):
```bash
# On your local machine
ssh-keygen -t ed25519 -C "proxmox-ignite" -f ~/.ssh/id_ed25519
# Accept defaults or set passphrase
# Result: ~/.ssh/id_ed25519.pub (public key)
```

## Installation Steps

### Step 1: Boot Fresh Proxmox ISO

1. Insert Proxmox 8.2 installation USB/boot from ISO
2. Select **"Install Proxmox VE"** (standard installer, NOT auto-install)
3. Complete basic installer:
   - Accept license
   - Select target disk (e.g., `/dev/nvme0n1`)
   - Set password (temporary, will be replaced)
   - Configure hostname (can be default, will be overridden)
   - Configure one network interface (DHCP is fine, will be replaced)
4. Complete installation and reboot
5. **Wait for Proxmox to fully boot** (~2–3 min from reboot)

### Step 2: Prepare SSH Key Transfer

On your local machine, copy the public key:
```bash
# Option A: Local file (for USB/SCP transfer)
cat ~/.ssh/id_ed25519.pub

# Option B: Direct SCP (after SSH is available)
# Will use this after first boot
```

### Step 3: Transfer SSH Key & Script to Proxmox Host

**Option A: USB Drive** (offline installation)
```bash
# On local machine
mkdir -p /mnt/usb
# Mount USB drive (macOS: /Volumes/USB, Linux: /mnt/usb)
cp ~/.ssh/id_ed25519.pub /mnt/usb/authorized_keys
cp proxmox-ignite.sh /mnt/usb/
# Unmount USB
```

Then on Proxmox host:
```bash
# Mount USB
mkdir -p /mnt/usb
mount /dev/sdb1 /mnt/usb  # Adjust device as needed
cp /mnt/usb/authorized_keys ~/.ssh/
cp /mnt/usb/proxmox-ignite.sh /tmp/
umount /mnt/usb
```

**Option B: Direct SCP** (online installation, requires temporary password)
```bash
# On local machine (after Proxmox boots with temporary credentials)
scp -P 22 ~/.ssh/id_ed25519.pub root@<proxmox-ip>:/root/.ssh/authorized_keys
scp -P 22 proxmox-ignite.sh root@<proxmox-ip>:/tmp/
```

### Step 4: Execute proxmox-ignite.sh

SSH into the host:
```bash
# Via IP (if DHCP is still active)
ssh root@<proxmox-ip>

# Via hostname (if configured)
ssh root@proxmox
```

Execute the ignition script:
```bash
sudo bash /tmp/proxmox-ignite.sh \
  --hostname rylan-dc \
  --ip 10.0.10.10/26 \
  --gateway 10.0.10.1 \
  --ssh-key ~/.ssh/authorized_keys
```

**Expected Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Phase 0: Validation & Prerequisites
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Running with root privileges
✅ Proxmox detected
... [phases 1–6] ...
████████████████████████████████████████████████████████████████████████████████
█                      ✅ PROXMOX IGNITE: SUCCESS                            █
████████████████████████████████████████████████████████████████████████████████

DEPLOYMENT SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Hostname:             rylan-dc
IP Address:           10.0.10.10/26
Gateway:              10.0.10.1
SSH Port:             22
... [summary] ...
```

**Total time**: ~12–14 minutes (depending on network speed)

## Usage Examples

### Standard Deployment
```bash
sudo ./proxmox-ignite.sh \
  --hostname rylan-dc \
  --ip 10.0.10.10/26 \
  --gateway 10.0.10.1 \
  --ssh-key ~/.ssh/id_ed25519.pub
```

### Deployment with Custom SSH Key
```bash
sudo ./proxmox-ignite.sh \
  --hostname rylan-dc \
  --ip 10.0.10.10/26 \
  --gateway 10.0.10.1 \
  --ssh-key /opt/keys/proxmox-admin.pub
```

### Skip Eternal Resurrection (faster testing)
```bash
sudo ./proxmox-ignite.sh \
  --hostname rylan-dc \
  --ip 10.0.10.10/26 \
  --gateway 10.0.10.1 \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --skip-eternal-resurrect
```

### Security Validation Only (audit mode)
```bash
sudo ./proxmox-ignite.sh \
  --hostname rylan-dc \
  --ip 10.0.10.10/26 \
  --gateway 10.0.10.1 \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --validate-only
```

### Display Help
```bash
sudo ./proxmox-ignite.sh --help
```

## Script Phases Explained

### Phase 0: Validation & Prerequisites
**Purpose**: Verify system state before making changes
- ✅ Check root privileges
- ✅ Verify Proxmox installation
- ✅ Test network connectivity
- ✅ Validate required tools (ip, git, curl, jq)
- ✅ Initialize log file

**Failure Mode**: Exit immediately if prerequisites fail

---

### Phase 1: Network Configuration (Suehring)
**Purpose**: Configure static IP, hostname, DNS (network isolation ready)

**Actions**:
1. Auto-detect primary ethernet NIC (en*, eth*)
2. Configure `/etc/network/interfaces.d/99-proxmox-ignite` with:
   - Static IP address
   - Netmask (derived from CIDR)
   - Default gateway
   - DNS servers (Primary: 10.0.10.10, Fallback: 1.1.1.1)
3. Apply via `ifup` command
4. Set hostname via `hostnamectl`
5. Update `/etc/hosts` for local resolution
6. Validate:
   - IP address assigned
   - Gateway reachable (ping)
   - DNS resolving (nslookup)

**Idempotence**: Safe to re-run; uses backup + sed for config updates

---

### Phase 2: SSH Hardening (Bauer & Carter)
**Purpose**: Inject SSH public key, disable passwords, enforce strong crypto (Carter identity + Bauer paranoia)

**Actions**:
1. Create `/root/.ssh` directory (700 permissions)
2. Inject SSH public key to `/root/.ssh/authorized_keys` (600 permissions)
3. Harden `/etc/ssh/sshd_config`:
   - `PasswordAuthentication no` (disable passwords)
   - `PermitRootLogin prohibit-password` (key-only for root)
   - `PubkeyAuthentication yes` (enforce public key)
   - `X11Forwarding no` (reduce attack surface)
   - Strong ciphers: `chacha20-poly1305@openssh.com, aes256-gcm@openssh.com`
   - Strong KEX: `curve25519-sha256, curve25519-sha256@libssh.org`
   - `PermitEmptyPasswords no` (Bauer paranoia)
4. Validate SSH config syntax with `sshd -t`
5. Restart SSH service

**Idempotence**: Uses grep + sed for safe updates; preserves existing config

---

### Phase 3: Tooling Bootstrap
**Purpose**: Install system and Python tools for fortress operations

**System Packages**:
- `git`: Repository management
- `curl`: HTTP client
- `python3`, `python3-pip`: Development environment
- `build-essential`: C compiler (for pip packages)
- `nmap`: Security scanning (Whitaker offensive)
- `jq`: JSON parsing
- `wget`: Downloader
- `ca-certificates`: SSL/TLS verification
- `net-tools`: Network diagnostics

**Python Packages**:
- `pre-commit`: Git hook framework (linting)
- `pytest`, `pytest-cov`: Testing framework
- `ruff`: Python linter (replaces flake8)
- `mypy`: Type checker
- `bandit`: Security scanner

**Actions**:
1. `apt-get update` with retry (network resilience)
2. Install system packages with retry
3. Upgrade pip, setuptools, wheel
4. Install Python packages via pip3
5. Configure git global config

---

### Phase 4: Repository Sync
**Purpose**: Clone/update fortress repository (GitOps-first deployment)

**Actions**:
1. Check if `/opt/fortress` exists:
   - If yes: Fetch + checkout branch + pull (idempotent update)
   - If no: Clone with `--depth 1` for speed
2. Checkout target branch: `feat/iot-production-ready`
3. Install pre-commit hooks (if `.pre-commit-config.yaml` exists)

**Repository Details**:
- **URL**: `https://github.com/T-Rylander/a-plus-up-unifi-case-study.git`
- **Branch**: `feat/iot-production-ready` (production-ready branch)
- **Destination**: `/opt/fortress` (standard installation path)

---

### Phase 5: Fortress Resurrection
**Purpose**: Execute eternal-resurrect.sh to restore LXCs/VMs from backups

**Actions**:
1. Check if `eternal-resurrect.sh` exists in repo
2. Execute with full error handling
3. Log all output to `/var/log/proxmox-ignite.log`

**Note**: Can be skipped with `--skip-eternal-resurrect` flag for faster testing

**Expected Output**:
- LXC containers spawned
- VM snapshots restored
- Networking bridges configured
- Services started

---

### Phase 6: Security Validation (Whitaker Offensive)
**Purpose**: Verify fortress hardening and report attack surface

**Tests Performed**:

| # | Test | Expected | Failure Impact |
|---|------|----------|-----------------|
| 1 | SSH port (22) open | ✅ Open | Critical (no access) |
| 2 | Proxmox web (8006) open | ✅ Open | Warning (may be starting) |
| 3 | Password auth disabled | ✅ Disabled | Critical (security breach) |
| 4 | Root login restricted | ✅ Key-only | Critical (weak auth) |
| 5 | SSH key installed | ✅ Present | Critical (no key auth) |
| 6 | Hostname correct | ✅ Match | Warning (DNS issues) |
| 7 | Static IP assigned | ✅ Assigned | Critical (network down) |
| 8 | Gateway reachable | ✅ Reachable | Critical (no connectivity) |
| 9 | DNS resolving | ✅ Working | Warning (will resolve after AD setup) |
| 10 | No dangerous ports | ✅ Closed (23, 80, 443) | Critical (attack surface) |

**Exit Behavior**:
- ✅ All tests pass: Exit 0 + success banner
- ❌ Any critical test fails: Exit 1 + failure banner

---

## Network Configuration Details

### IP Address Assignment

The script configures `/etc/network/interfaces.d/99-proxmox-ignite`:

```bash
auto eth0                    # Example NIC (auto-detected)
iface eth0 inet static
  address 10.0.10.10         # Primary IP (from --ip param)
  netmask 255.255.255.192    # Derived from CIDR (/26 = 4 hosts)
  gateway 10.0.10.1          # Default gateway
  dns-nameservers 10.0.10.10 1.1.1.1  # DNS servers
  mtu 1500
```

### CIDR to Netmask Mapping

| CIDR | Netmask | Hosts | Use Case |
|------|---------|-------|----------|
| /24 | 255.255.255.0 | 254 | Large network |
| /25 | 255.255.255.128 | 126 | Medium network |
| /26 | 255.255.255.192 | 62 | Small network (default for rylan-dc) |
| /27 | 255.255.255.224 | 30 | Tiny network |
| /28 | 255.255.255.240 | 14 | Point-to-point |

### DNS Configuration

| Server | Purpose | Used When |
|--------|---------|-----------|
| 10.0.10.10 | Primary (Carter AD/DNS) | AD domain name resolution |
| 1.1.1.1 | Fallback (Cloudflare) | Primary DNS unavailable |

---

## SSH Hardening Details

### Hardened Configuration

The script sets these SSH parameters:

```bash
# Authentication
PasswordAuthentication no               # No password login
PermitRootLogin prohibit-password       # Root key-only
PubkeyAuthentication yes                # Enable public key
PermitEmptyPasswords no                 # No empty passwords

# Crypto (forward-secrecy only)
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org

# Attack surface reduction
X11Forwarding no                        # Disable X11 proxy
```

### Key Authentication

After hardening, only ed25519/RSA public keys work:

```bash
# Works (key-based)
ssh -i ~/.ssh/id_ed25519 root@rylan-dc

# Fails (password attempt)
ssh root@rylan-dc
# Permission denied (publickey)
```

---

## Logging & Debugging

### Log File Location
```bash
/var/log/proxmox-ignite.log
```

### Real-Time Monitoring
```bash
# In another terminal
tail -f /var/log/proxmox-ignite.log
```

### Log Format
```
[2025-12-05 14:23:45] [INFO] Phase 1: Network Configuration (Suehring)
[2025-12-05 14:23:46] [INFO] Detecting primary ethernet NIC...
[2025-12-05 14:23:46] [INFO] ✅ Primary NIC detected: eth0
```

### Debug Output (if script fails)
```bash
# Run with verbose output
bash -x ./proxmox-ignite.sh --hostname rylan-dc --ip 10.0.10.10/26 --gateway 10.0.10.1 --ssh-key ~/.ssh/id_ed25519.pub
```

---

## Troubleshooting

### Issue: "No ethernet NIC found"

**Symptom**: Phase 1 fails with "No ethernet NIC found"

**Causes**:
- Network interface not detected
- Interface named unusually (not en*, eth*)

**Solution**:
```bash
# Check available NICs
ip -o link show

# Example output:
# 1: lo: <LOOPBACK,UP,LOWER_UP>
# 2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP>

# If you see "ens3", it's supported
# If different, modify script NIC detection regex
```

---

### Issue: "Cannot reach gateway"

**Symptom**: Phase 1 fails with "Cannot reach gateway: 10.0.10.1"

**Causes**:
- Gateway IP incorrect
- Physical network disconnected
- Switch/router not responding

**Solution**:
```bash
# Manually verify network
ip addr show               # Check if IP assigned
ping 10.0.10.1             # Test gateway
ping 8.8.8.8               # Test internet
route -n                   # Check routing table
```

---

### Issue: "SSH key file not found"

**Symptom**: Script fails with "SSH key file not found: ~/.ssh/id_ed25519.pub"

**Causes**:
- Wrong path provided
- File doesn't exist

**Solution**:
```bash
# Verify SSH key exists
ls -la ~/.ssh/id_ed25519.pub

# Generate if missing
ssh-keygen -t ed25519 -C "proxmox-ignite" -f ~/.ssh/id_ed25519

# Use full path (not ~)
sudo ./proxmox-ignite.sh \
  ... \
  --ssh-key /root/.ssh/id_ed25519.pub
```

---

### Issue: "Permission denied (publickey)"

**Symptom**: Cannot SSH after script completes

**Causes**:
- SSH key not installed correctly
- SSH config validation failed
- SSH service not restarted

**Solution**:
```bash
# Verify SSH key on host
ssh root@hostname "cat ~/.ssh/authorized_keys"

# Check SSH config
ssh root@hostname "grep PasswordAuthentication /etc/ssh/sshd_config"

# Restart SSH manually
ssh root@hostname "systemctl restart ssh"
```

---

### Issue: "Script takes >15 minutes"

**Symptom**: Execution slow despite automation

**Causes**:
- Slow network (GitHub clone)
- Large repository
- Package download bottleneck

**Solution**:
```bash
# Use faster DNS
# (script uses 1.1.1.1 by default)

# Skip eternal-resurrect for faster testing
sudo ./proxmox-ignite.sh \
  ... \
  --skip-eternal-resurrect

# Monitor network
tail -f /var/log/proxmox-ignite.log | grep "Executing"
```

---

### Issue: "Security validation failed"

**Symptom**: Script exits 1 with "Security validation failed"

**Causes**:
- SSH hardening incomplete
- Port configuration issue
- nmap scan failed

**Solution**:
```bash
# Run validation-only mode for diagnosis
sudo ./proxmox-ignite.sh \
  ... \
  --validate-only

# Check sshd config manually
sudo sshd -T | grep "PasswordAuthentication\|PermitRootLogin"

# Verify ports
sudo netstat -tlnp | grep -E ":22|:8006"
```

---

## CI/CD Integration

### GitHub Actions Workflow

The repository includes CI tests for this script:

```yaml
# .github/workflows/ci-proxmox-ignite.yaml
name: Proxmox Ignite CI

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: ShellCheck
        run: shellcheck 01-bootstrap/proxmox/proxmox-ignite.sh
      - name: Bandit (Python security scan)
        run: bandit -r . -ll

  test-preseed:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate preseed file
        run: grep -E "^[a-z-]+ " proxmox-answer.cfg
```

### Manual Testing

To test the script locally:

```bash
# 1. Lint check
shellcheck 01-bootstrap/proxmox/proxmox-ignite.sh

# 2. Dry-run (validation only, no changes)
sudo ./01-bootstrap/proxmox/proxmox-ignite.sh \
  --hostname test-host \
  --ip 10.0.10.20/26 \
  --gateway 10.0.10.1 \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --validate-only

# 3. Full test on QEMU VM (optional)
# See docs/testing/qemu-proxmox-test.md for setup
```

---

## Performance Metrics

### Target RTO: <15 minutes

Breakdown by phase (typical execution):

| Phase | Time | Activity |
|-------|------|----------|
| Validation & Prerequisites | 30 sec | System checks |
| Network Configuration | 1 min | IP assignment, NIC config |
| SSH Hardening | 30 sec | Key injection, SSH config |
| Tooling Bootstrap | 4–5 min | apt-get, pip3 install |
| Repository Sync | 2–3 min | git clone (network-dependent) |
| Fortress Resurrection | 2–3 min | eternal-resurrect.sh |
| Security Validation | 1 min | nmap, SSH tests |
| **Total** | **11–13 min** | (varies with network) |

**Optimization Tips**:
- Use faster internet (for git clone)
- Skip `--skip-eternal-resurrect` during testing
- Pre-cache packages (apt-get cache mount)

---

## Security Guarantees

### Whitaker Offensive: Attack Surface Validation

The script ensures:
- ✅ **SSH Key-Only**: No password authentication possible
- ✅ **No Default Passwords**: Temporary password from installer removed
- ✅ **Strong Cryptography**: ed25519 keys, ChaCha20-Poly1305 ciphers
- ✅ **Minimal Ports**: Only 22 (SSH), 8006 (Proxmox), 3128 (cluster)
- ✅ **No X11 Proxy**: Reduces remote attack surface
- ✅ **Validated**: nmap scans confirm attack surface reduced

### Bauer Paranoia: Defense-in-Depth

- ✅ **Auditability**: All commands logged to `/var/log/proxmox-ignite.log`
- ✅ **Idempotence**: Safe to re-run on partial failure
- ✅ **Rollback**: Original configs backed up (`.bak` files)
- ✅ **Validation**: Each phase tests before proceeding

### Carter Identity: Domain-Ready

- ✅ **SSH Key Injection**: Public key installed at first boot
- ✅ **Hostname Resolution**: `/etc/hosts` updated for local domain
- ✅ **DNS Configuration**: Primary (Carter AD) + fallback (Cloudflare)
- ✅ **Static IP**: No DHCP dependency; AD-ready infrastructure

---

## Next Steps After Deployment

### 1. Verify SSH Access
```bash
ssh -i ~/.ssh/id_ed25519 root@rylan-dc
```

### 2. Access Proxmox Web UI
```
https://rylan-dc:8006
  Username: root@pam
  Password: (temporary, from installer)
```

### 3. Run Fortress Validation
```bash
cd /opt/fortress
sudo ./validate-eternal.sh
```

### 4. Review Logs
```bash
tail -50 /var/log/proxmox-ignite.log
```

### 5. Continue with Carter (Samba AD/DC)
```bash
cd /opt/fortress
sudo ./01-bootstrap/samba-provision.sh
```

---

## Support & Debugging

### Enable Verbose Output
```bash
# Run script with shell debugging
bash -x ./proxmox-ignite.sh --hostname rylan-dc --ip 10.0.10.10/26 --gateway 10.0.10.1 --ssh-key ~/.ssh/id_ed25519.pub 2>&1 | tee debug.log
```

### Extract Phase Output
```bash
# View specific phase logs
grep "Phase 3" /var/log/proxmox-ignite.log

# Follow phase execution in real-time
tail -f /var/log/proxmox-ignite.log | grep -E "Phase|✅|❌"
```

### Contact Support

For issues, check:
1. `/var/log/proxmox-ignite.log` (main log)
2. `./docs/troubleshooting/` (docs)
3. GitHub Issues (repository)

---

## License

This script is part of the a-plus-up-unifi-case-study project and is released under the same license as the parent repository. See `LICENSE` file for details.

## References

- [Proxmox VE 8.2 Documentation](https://pve.proxmox.com/wiki)
- [Automated Installation Guide](https://pve.proxmox.com/wiki/Automated_Installation)
- [SSH Security Hardening (OpenSSH)](https://man.openbsd.org/sshd_config)
- [T3-ETERNAL Framework](../../../INSTRUCTION-SET-ETERNAL-v1.md)
