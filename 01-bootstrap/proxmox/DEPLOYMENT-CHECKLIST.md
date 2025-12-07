# Proxmox Ignite Deployment Checklist

Quick reference guide for executing proxmox-ignite.sh deployment.

## Pre-Deployment (Local Machine)

- [ ] Generate SSH key (if not present):
  ```bash
  ssh-keygen -t ed25519 -C "proxmox-ignite" -f ~/.ssh/id_ed25519
  ```

- [ ] Verify SSH key exists:
  ```bash
  cat ~/.ssh/id_ed25519.pub  # Should output: ssh-ed25519 AAAA...
  ```

- [ ] Clone repository (if not already present):
  ```bash
  git clone https://github.com/T-Rylander/a-plus-up-unifi-case-study.git
  cd a-plus-up-unifi-case-study
  ```

- [ ] Verify script exists:
  ```bash
  ls -la 01-bootstrap/proxmox/proxmox-ignite.sh
  ```

## Hardware Preparation

- [ ] Verify hardware meets requirements:
  - [ ] CPU: Modern x86-64 (Intel Z390 or AMD Ryzen 3000+)
  - [ ] RAM: ≥32 GB
  - [ ] Storage: ≥250 GB NVMe SSD
  - [ ] Network: 1 Gbps Ethernet

- [ ] Prepare Proxmox installation media:
  - [ ] Download Proxmox VE 8.2 ISO
  - [ ] Create bootable USB (balena Etcher, Ventoy, dd)
  - [ ] Verify USB is bootable

- [ ] Network prerequisites:
  - [ ] Verify IP range is available (e.g., 10.0.10.0/26)
  - [ ] Confirm gateway IP (e.g., 10.0.10.1)
  - [ ] Test gateway connectivity from another host

## Proxmox Installation (Manual)

- [ ] Boot Proxmox ISO on target hardware
- [ ] Select **"Install Proxmox VE"** (standard installer)
- [ ] Accept license terms
- [ ] Select target disk (e.g., `/dev/nvme0n1`)
- [ ] Set temporary root password (will be replaced)
- [ ] Configure hostname (temporary, will be replaced)
- [ ] Configure one network interface (DHCP acceptable)
- [ ] Complete installation
- [ ] Wait for Proxmox to boot fully (~3 minutes)
- [ ] Note the temporary hostname/IP from boot screen

## Transfer ignition script to Proxmox host

**Option A: USB Transfer (Offline)**
```bash
# On local machine
mkdir -p /mnt/usb
# Mount USB drive
cp ~/.ssh/id_ed25519.pub /mnt/usb/authorized_keys
cp 01-bootstrap/proxmox/proxmox-ignite.sh /mnt/usb/
umount /mnt/usb

# On Proxmox host (after booting)
mkdir -p /mnt/usb
mount /dev/sdb1 /mnt/usb  # Adjust device name
cp /mnt/usb/authorized_keys ~/.ssh/
cp /mnt/usb/proxmox-ignite.sh /tmp/
umount /mnt/usb
```

**Option B: SCP Transfer (Online)**
```bash
# On local machine
scp ~/.ssh/id_ed25519.pub root@<proxmox-ip>:/root/.ssh/authorized_keys
scp 01-bootstrap/proxmox/proxmox-ignite.sh root@<proxmox-ip>:/tmp/
```

## Execute ignition script

- [ ] SSH into Proxmox host:
  ```bash
  ssh root@<proxmox-ip>
  # or
  ssh root@<hostname-from-install>
  ```

- [ ] Verify script permissions:
  ```bash
  ls -la /tmp/proxmox-ignite.sh
  chmod +x /tmp/proxmox-ignite.sh
  ```

- [ ] Run ignition script:
  ```bash
  sudo bash /tmp/proxmox-ignite.sh \
    --hostname rylan-dc \
    --ip 10.0.10.10/26 \
    --gateway 10.0.10.1 \
    --ssh-key ~/.ssh/authorized_keys
  ```

- [ ] Monitor execution:
  - Watch for phase progress indicators (Phase 0–6)
  - Typical execution time: 11–14 minutes
  - Check `/var/log/proxmox-ignite.log` if script stalls

- [ ] Verify success banner:
  ```
  ████████████████████████████████████████████████████████████████
  █                    ✅ PROXMOX IGNITE: SUCCESS                 █
  ████████████████████████████████████████████████████████████████
  ```

## Post-Deployment Validation

- [ ] SSH into host with key-only auth:
  ```bash
  ssh -i ~/.ssh/id_ed25519 root@rylan-dc
  # Should succeed with key, fail without
  ```

- [ ] Verify hostname:
  ```bash
  hostname
  # Should output: rylan-dc
  ```

- [ ] Verify static IP:
  ```bash
  ip addr show
  # Should show: inet 10.0.10.10/26
  ```

- [ ] Verify gateway reachability:
  ```bash
  ping 10.0.10.1
  ```

- [ ] Verify DNS resolution:
  ```bash
  nslookup google.com
  ```

- [ ] Access Proxmox Web UI:
  ```
  https://rylan-dc:8006
  Username: root@pam
  Password: (temporary, from Proxmox installer)
  ```

- [ ] Run fortress validation:
  ```bash
  cd /opt/fortress
  ./validate-eternal.sh
  # Should show: 100% PASS
  ```

- [ ] Review ignition log:
  ```bash
  tail -100 /var/log/proxmox-ignite.log
  # Should end with: Proxmox Ignite completed successfully
  ```

## Security Hardening Verification

- [ ] Verify SSH hardening:
  ```bash
  sudo grep "PasswordAuthentication" /etc/ssh/sshd_config
  # Should show: PasswordAuthentication no
  
  sudo grep "PermitRootLogin" /etc/ssh/sshd_config
  # Should show: PermitRootLogin prohibit-password
  ```

- [ ] Verify SSH key installed:
  ```bash
  cat ~/.ssh/authorized_keys
  # Should show your SSH public key
  ```

- [ ] Verify only required ports open:
  ```bash
  sudo nmap localhost -p 1-10000 | grep open
  # Should only show: 22/tcp open (SSH), 8006/tcp open (Proxmox)
  ```

- [ ] Attempt password login (should fail):
  ```bash
  ssh -o PasswordAuthentication=yes root@rylan-dc
  # Should output: Permission denied (publickey)
  ```

## Network Verification

- [ ] Ping gateway:
  ```bash
  ping 10.0.10.1
  # Should respond
  ```

- [ ] Ping external DNS:
  ```bash
  ping 1.1.1.1
  # Should respond
  ```

- [ ] Test DNS resolution:
  ```bash
  nslookup google.com
  # Should return: 142.251.x.x (or similar IP)
  ```

- [ ] Verify routing table:
  ```bash
  route -n
  # Default route should point to 10.0.10.1
  ```

## Troubleshooting Checklist

If deployment fails, verify in order:

- [ ] Script has execute permissions:
  ```bash
  ls -la /tmp/proxmox-ignite.sh | grep -E "^-rwx"
  ```

- [ ] SSH key is valid:
  ```bash
  ssh-keygen -lf ~/.ssh/authorized_keys
  # Should show key fingerprint
  ```

- [ ] Network is reachable:
  ```bash
  ping 10.0.10.1
  ```

- [ ] Root access is available:
  ```bash
  whoami
  # Should output: root
  ```

- [ ] Proxmox is installed:
  ```bash
  grep Proxmox /etc/os-release
  ```

- [ ] Check log file for errors:
  ```bash
  sudo tail -200 /var/log/proxmox-ignite.log | grep -E "ERROR|Failed"
  ```

- [ ] Run validation-only mode (non-destructive):
  ```bash
  sudo bash /tmp/proxmox-ignite.sh \
    --hostname rylan-dc \
    --ip 10.0.10.10/26 \
    --gateway 10.0.10.1 \
    --ssh-key ~/.ssh/authorized_keys \
    --validate-only
  ```

## Quick Reference

### Typical deployment timeline:
- T+0 min: Start script
- T+1 min: Phase 0 (validation)
- T+2 min: Phase 1 (network)
- T+3 min: Phase 2 (SSH)
- T+4 min: Phase 3 (tooling bootstrap)
- T+7 min: Phase 4 (repository)
- T+10 min: Phase 5 (resurrection)
- T+12 min: Phase 6 (validation)
- T+12 min: Success banner

### Common parameters:
```bash
# Lab environment (default)
--hostname rylan-dc \
--ip 10.0.10.10/26 \
--gateway 10.0.10.1 \
--ssh-key ~/.ssh/id_ed25519.pub

# Production environment
--hostname proxmox-prod \
--ip 192.168.1.10/24 \
--gateway 192.168.1.1 \
--ssh-key /opt/keys/proxmox.pub
```

### Log locations:
- Main log: `/var/log/proxmox-ignite.log`
- SSH config: `/etc/ssh/sshd_config`
- Network config: `/etc/network/interfaces.d/99-proxmox-ignite`
- Repository: `/opt/fortress`

### Supported CIDR ranges:
- /24: 254 usable hosts
- /25: 126 usable hosts
- /26: 62 usable hosts (recommended for lab)
- /27: 30 usable hosts
- /28: 14 usable hosts

---

For detailed documentation, see `README.md` in the same directory.
