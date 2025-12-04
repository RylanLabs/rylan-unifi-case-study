# Samba AD/DC Multipass Validation Troubleshooting

## Overview

This guide addresses common issues when running `bootstrap/samba-dc-test.ps1` on Windows with Hyper-V and Multipass.

---

## Issue: VM Launch Fails with Hyper-V Error

**Symptom**: `multipass launch` fails with "Hyper-V not available" or "Failed to create VM"

### Diagnosis

Check Hyper-V status:

```powershell
# Verify Hyper-V is enabled
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# Should show: State : Enabled
```

Check Multipass installation:

```powershell
multipass version
# Should show version info
```

### Root Causes

| Cause | Indicator | Fix |
|-------|-----------|-----|
| Hyper-V not enabled | FeatureState: "Disabled" | Run "Enable Hyper-V" (see below) |
| Virtualization disabled in BIOS | VT-x/AMD-V not available | Reboot, enter BIOS, enable virtualization |
| Hyper-V daemon not running | VM creation hangs | Restart Hyper-V service |
| Insufficient disk space | "No space left on device" | Free up 20GB+ |
| Conflicting hypervisors (VirtualBox) | Port conflicts | Uninstall VirtualBox or use Hyper-V exclusively |

### Fix Options

#### Option 1: Enable Hyper-V (Requires Reboot)

```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Reboot system
Restart-Computer
```

#### Option 2: Restart Hyper-V Service

```powershell
# Run as Administrator
Restart-Service vmms  # Virtual Machine Management Service
Get-Service vmms | Select-Object Status
```

#### Option 3: Check Disk Space

```powershell
# Multipass VMs require ~20GB per instance
Get-PSDrive C | Select-Object Used, Free
# Should have >25GB free
```

#### Option 4: Force VM Hypervisor Reset

```powershell
# If Hyper-V becomes corrupted
multipass purge
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Restart-Computer
```

---

## Issue: Network Bridging Fails / No Internet Access

**Symptom**: VM has no internet, `apt update` fails, or IP assignment incomplete

### Diagnosis

Check bridged network configuration:

```powershell
# List available Hyper-V networks
Get-VMSwitch -SwitchType External

# List VM network adapter status
multipass exec $VM_NAME -- ip addr show
multipass exec $VM_NAME -- ping -c 1 1.1.1.1
```

Check Multipass bridging:

```powershell
multipass get local.bridged-network
# Should show active adapter name (e.g., "Ethernet", "Default Switch")
```

### Root Causes

| Cause | Symptom | Fix |
|-------|---------|-----|
| No external Hyper-V switch | VM isolated (NAT only) | Create external switch (see Option 1) |
| Bridged network misconfigured | Multipass returns empty string | Set bridged network explicitly |
| Network adapter down | `ip link show` shows DOWN | Enable adapter or switch networks |
| DNS not forwarding | Ping works, apt fails on DNS | Update `/etc/resolv.conf` |
| Host firewall blocking | Cannot reach 1.1.1.1 | Allow outbound on host firewall |

### Fix Options

#### Option 1: Create External Hyper-V Switch (One-time)

```powershell
# Run as Administrator

# List network adapters
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

# Create external switch bound to active adapter
New-VMSwitch -Name "ExternalSwitch" -NetAdapterName "Ethernet" -AllowManagementOS $true

# Set Multipass to use it
multipass set local.bridged-network="ExternalSwitch"
```

#### Option 2: Use Default Switch (Simpler, NAT-based)

```powershell
# Default Switch provides NAT access automatically
multipass set local.bridged-network=""  # Clear custom setting
# VM will use Default Switch (built-in)
```

#### Option 3: Force VM Network Reconfiguration

```powershell
# Stop VM and restart network
multipass stop $VM_NAME
Start-Sleep -Seconds 3
multipass start $VM_NAME

# Re-run Step 2 of samba-dc-test.ps1 (static IP config)
```

#### Option 4: Verify DNS Inside VM

```powershell
# Check DNS resolution inside VM
multipass exec $VM_NAME -- cat /etc/resolv.conf
# Should list 1.1.1.1 or 8.8.8.8

# Test DNS resolution
multipass exec $VM_NAME -- nslookup archive.ubuntu.com 1.1.1.1
# Should return IP address
```

---

## Issue: Samba Provision Fails with "Role Conflict"

**Symptom**: `samba-tool domain provision` fails with "server role conflict" or "already provisioned"

### Diagnosis

Check for existing Samba configuration:

```bash
multipass exec $VM_NAME -- sudo cat /etc/samba/smb.conf
# Should return empty if not provisioned

multipass exec $VM_NAME -- ls -la /var/lib/samba/
# Should be mostly empty
```

Check systemd service state:

```bash
multipass exec $VM_NAME -- sudo systemctl status smbd nmbd winbind
# Should show "inactive (dead)" if not yet started
```

### Root Causes

| Cause | Check | Fix |
|-------|-------|-----|
| Previous provision left smb.conf | File exists and has content | Step 4 should clean this (re-run if persists) |
| /var/lib/samba not cleaned | `ls` shows .ldb files | Run `sudo rm -rf /var/lib/samba/*` |
| Conflicting services running | nmbd/smbd active | Stop services before provision (Step 4) |
| Incomplete prior run | sam.ldb exists but partial | Full cleanup and re-run |

### Fix Options

#### Option 1: Manual Full Cleanup (Already in Step 4)

```bash
multipass exec $VM_NAME -- sudo systemctl stop smbd nmbd winbind samba-ad-dc 2>/dev/null || true
multipass exec $VM_NAME -- sudo systemctl disable smbd nmbd winbind samba-ad-dc 2>/dev/null || true

# Remove all Samba artifacts
multipass exec $VM_NAME -- sudo rm -f /etc/samba/smb.conf
multipass exec $VM_NAME -- sudo rm -rf /var/lib/samba/*
multipass exec $VM_NAME -- sudo rm -rf /var/cache/samba/*

# Re-run provision (Step 5 in script)
```

#### Option 2: Delete and Recreate VM

```powershell
# Fastest way to recover from "role conflict"
multipass delete $VM_NAME --purge
# Re-run samba-dc-test.ps1 from scratch
```

#### Option 3: Verify Provision Succeeded

```bash
# After provision completes, verify success
multipass exec $VM_NAME -- ls -la /var/lib/samba/private/sam.ldb
# Should exist and be non-empty (>10MB)

multipass exec $VM_NAME -- cat /etc/samba/smb.conf | head -20
# Should show [global] section with configured realm
```

---

## Issue: DNS Resolution Fails

**Symptom**: `host -t SRV _ldap._tcp.rylan.internal` returns no records or times out

### Diagnosis

Check Samba DNS service:

```bash
# Verify service is running
multipass exec $VM_NAME -- sudo systemctl status samba-ad-dc
# Should show "active (running)"

# Check DNS backend is configured
multipass exec $VM_NAME -- cat /etc/samba/smb.conf | grep "dns backend"
# Should show "dns backend = SAMBA_INTERNAL"
```

Query Samba DNS directly:

```bash
multipass exec $VM_NAME -- sudo samba-tool dns query localhost rylan.internal @ ALL
# Should list SOA, NS, A records

multipass exec $VM_NAME -- sudo samba-tool dns query localhost _ldap._tcp.rylan.internal SRV
# Should show LDAP SRV records
```

Check system resolver:

```bash
multipass exec $VM_NAME -- cat /etc/resolv.conf
# Should list localhost (127.0.0.1) or DC IP as first nameserver

multipass exec $VM_NAME -- nslookup rylan.internal 10.0.10.10
# Should resolve to 10.0.10.10
```

### Root Causes

| Cause | Symptom | Fix |
|-------|---------|-----|
| Samba service not started | systemctl shows "inactive" | Run Step 7 (start service) |
| DNS forwarder config broken | `samba-tool dns query` fails | Restart Samba or reapply config |
| /etc/resolv.conf not updated | `cat` shows no nameserver | Run Step 6 (DNS config) |
| Samba DNS zone not created | Query returns empty | Provision may have failed; check Step 5 logs |
| Time sync issue | Kerberos DNS fails | Verify NTP: `timedatectl status` |

### Fix Options

#### Option 1: Restart Samba AD/DC Service

```bash
multipass exec $VM_NAME -- sudo systemctl restart samba-ad-dc
multipass exec $VM_NAME -- sudo systemctl status samba-ad-dc
Start-Sleep -Seconds 5

# Retry DNS query
multipass exec $VM_NAME -- host -t SRV _ldap._tcp.rylan.internal
```

#### Option 2: Verify DNS Zone Created

```bash
# Query Samba DNS for all records
multipass exec $VM_NAME -- sudo samba-tool dns zonelist localhost

# Should list "rylan.internal"
```

#### Option 3: Check Provision Logs

```bash
# If provision failed, logs are in:
multipass exec $VM_NAME -- sudo cat /var/log/samba/provision.log
# Look for errors; common issue is DNS backend misconfiguration

# If not found, check general Samba logs:
multipass exec $VM_NAME -- sudo journalctl -u samba-ad-dc -n 100
```

#### Option 4: Manual resolv.conf Update

```bash
# If Step 6 didn't apply correctly
multipass exec $VM_NAME -- sudo bash -c "cat > /etc/resolv.conf << 'EOF'
search rylan.internal
nameserver 10.0.10.10
nameserver 1.1.1.1
EOF"

# Test resolution
multipass exec $VM_NAME -- nslookup rylan.internal
```

---

## Issue: Kerberos Authentication Fails

**Symptom**: `kinit administrator@RYLAN.INTERNAL` fails with "Cannot contact KDC" or "Client not found in Kerberos database"

### Diagnosis

Check Kerberos configuration:

```bash
# Verify krb5.conf is present and configured
multipass exec $VM_NAME -- cat /etc/krb5.conf
# Should show [libdefaults], [realms] sections with RYLAN.INTERNAL

# Check KDC is listening
multipass exec $VM_NAME -- nc -zv 10.0.10.10 88
# Should show "succeeded" (port 88 is Kerberos)
```

Check time synchronization:

```bash
# Kerberos requires <5 min clock skew between client and DC
multipass exec $VM_NAME -- timedatectl
# NTP should be "System clock synchronized: yes"

# Manually sync if needed
multipass exec $VM_NAME -- sudo timedatectl set-ntp on
```

Check Kerberos database:

```bash
# Verify administrative user in database
multipass exec $VM_NAME -- sudo samba-tool user list
# Should show "Administrator" (capital A)
```

### Root Causes

| Cause | Check | Fix |
|-------|-------|-----|
| krb5.conf not updated | `/etc/krb5.conf` empty or missing | Re-run Step 6 |
| KDC service (Samba) not running | `systemctl status samba-ad-dc` shows dead | Restart service (Step 7) |
| Time not synced | `timedatectl` shows skew >5 min | Sync time or restart VM |
| Administrator user not created | `samba-tool user list` empty | Provision failed; check provision logs |
| Hostname not resolving | `hostname -f` doesn't resolve | Update /etc/hosts or DNS |

### Fix Options

#### Option 1: Reconfigure Kerberos

```bash
# Recopy krb5.conf from Samba
multipass exec $VM_NAME -- sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Verify configuration
multipass exec $VM_NAME -- cat /etc/krb5.conf | grep -A 5 "\[libdefaults\]"

# Restart Samba
multipass exec $VM_NAME -- sudo systemctl restart samba-ad-dc
Start-Sleep -Seconds 5
```

#### Option 2: Sync System Time

```bash
# Force NTP sync
multipass exec $VM_NAME -- sudo timedatectl set-ntp off
multipass exec $VM_NAME -- sudo timedatectl set-ntp on
Start-Sleep -Seconds 3

# Verify sync
multipass exec $VM_NAME -- timedatectl
# Should show "System clock synchronized: yes"
```

#### Option 3: Test Kinit with Verbose Output

```bash
# Run kinit with debug output
multipass exec $VM_NAME -- bash -c "echo 'Passw0rd123!' | kinit -V administrator@RYLAN.INTERNAL 2>&1"

# Look for specific error:
# - "Client not found": User not in database (provision failed)
# - "Cannot contact KDC": Port 88 not listening (service not running)
# - "Preauth failed": Wrong password
```

#### Option 4: Reset Kerberos Credentials

```bash
# Clear any cached credentials
multipass exec $VM_NAME -- kdestroy 2>/dev/null || true

# Try kinit again
multipass exec $VM_NAME -- bash -c "echo 'Passw0rd123!' | kinit administrator@RYLAN.INTERNAL && klist"
```

---

## Issue: LDAP Search Fails

**Symptom**: `ldapsearch` command fails to connect or returns empty results

### Diagnosis

Check LDAP service availability:

```bash
# Test LDAP port connectivity
multipass exec $VM_NAME -- nc -zv 10.0.10.10 389
# Should show "succeeded"

# Test LDAPS (secure LDAP) port
multipass exec $VM_NAME -- nc -zv 10.0.10.10 636
# Should show "succeeded" (if TLS configured)
```

Check LDAP base DN:

```bash
# Verify DN structure
multipass exec $VM_NAME -- samba-tool domain info 10.0.10.10
# Should show "Domain Name: rylan", "Domain DN: DC=rylan,DC=internal"
```

### Root Causes

| Cause | Check | Fix |
|-------|-------|-----|
| LDAP not running | `samba-tool` shows no info | Start Samba service |
| Incorrect base DN | DN not showing internal domain | Provision may have failed |
| Authentication failed | ldapsearch returns "Invalid credentials" | Check admin password in Step 5 |
| DC not listening | Port 389 unreachable | Verify DC IP and firewall |

### Fix Options

#### Option 1: Test LDAP Anonymously

```bash
# Simple LDAP search (anonymous)
multipass exec $VM_NAME -- ldapsearch -x -H ldap://10.0.10.10 -b "dc=rylan,dc=internal" "(objectClass=*)" | head -20

# If this works, LDAP is functional; auth issue may be elsewhere
```

#### Option 2: Test LDAP with Administrator Credentials

```bash
# LDAP search with admin bind
multipass exec $VM_NAME -- ldapsearch -x \
    -H ldap://10.0.10.10 \
    -D "cn=Administrator,cn=Users,dc=rylan,dc=internal" \
    -w "Passw0rd123!" \
    -b "dc=rylan,dc=internal" \
    "(objectClass=user)"

# Should list user objects (at minimum, Administrator)
```

#### Option 3: Check LDAP Logs

```bash
# View Samba LDAP debug logs
multipass exec $VM_NAME -- sudo journalctl -u samba-ad-dc -n 100 | grep -i ldap

# Or check Samba debug logs
multipass exec $VM_NAME -- sudo tail -50 /var/log/samba/log.sambadomain
```

---

## Issue: SMB Share Access Fails

**Symptom**: `smbclient` commands fail or show no shares

### Diagnosis

Check SMB service:

```bash
# Test SMB ports
multipass exec $VM_NAME -- nc -zv 10.0.10.10 139
multipass exec $VM_NAME -- nc -zv 10.0.10.10 445
# Should both show "succeeded"

# Check shares
multipass exec $VM_NAME -- smbclient -L 10.0.10.10 -N
# Should list "Sharename", including "netlogon", "sysvol"
```

### Root Causes

| Cause | Check | Fix |
|-------|-------|-----|
| SMB service not running | `smbclient -L` hangs or fails | Ensure samba-ad-dc is running |
| Authentication failed | "NT_STATUS_LOGON_FAILURE" | Verify admin password |
| Shares not created | Only "IPC$" shown | Provision may have failed |
| Firewall blocking SMB | Ports 139/445 unreachable | Check host firewall or Hyper-V security policy |

### Fix Options

#### Option 1: Restart SMB Services

```bash
multipass exec $VM_NAME -- sudo systemctl restart samba-ad-dc
Start-Sleep -Seconds 5

# Retry share listing
multipass exec $VM_NAME -- smbclient -L localhost -N
```

#### Option 2: Verify Share Creation

```bash
# List shares with samba-tool
multipass exec $VM_NAME -- sudo samba-tool share list

# Should include:
# - netlogon: \\.\sysvol\rylan.internal\scripts
# - sysvol: \\.\sysvol
```

---

## Trinity Compliance Verification

### Carter: Programmable Identity

Verify all configuration is declared (no interactive input):

```bash
# Check for hardcoded values in script (no user prompts)
grep -i "read-host" bootstrap/samba-dc-test.ps1
# Should return empty (no interactive reads)

# All parameters are declared at top of script
grep "^\$" bootstrap/samba-dc-test.ps1 | head -10
```

### Bauer: Verify Everything

Validation tests are run (Step 8):

```bash
# Each test verifies critical functionality
# 1. SMB share access
# 2. LDAP authentication
# 3. DNS SRV records
# 4. Kerberos tickets
# 5. Domain functional level
```

### Suehring: Network First

Network is configured before Samba:

```bash
# Step 2 configures static IP before Step 3 (installation)
# Step 6 configures DNS before Step 7 (service start)
```

---

## Rollback / Complete Cleanup

### Clean VM Deletion

```powershell
# Safe deletion (all VM data removed)
multipass delete $VM_NAME --purge
```

### Force Cleanup (If VM Stuck)

```powershell
# Stop all VMs
multipass stop --all

# Delete VM
multipass delete $VM_NAME --purge

# Restart Multipass daemon
multipass restart
```

### Multipass Complete Reset (Nuclear Option)

```powershell
# Remove all VMs and cached images (WARNING: destructive)
multipass purge
```

---

## References

- **Samba Wiki**: https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller
- **Multipass Documentation**: https://multipass.run/docs
- **Hyper-V Virtual Networking**: https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/plan-hyper-v-networking
- **Kerberos Troubleshooting**: https://web.mit.edu/kerberos/
- **LDAP Command-line Tools**: https://linux.die.net/man/1/ldapsearch
