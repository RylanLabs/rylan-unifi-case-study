# bootstrap/samba-dc-test.ps1
# Samba AD/DC Validation in Multipass VM (Windows Host)
# Aligns with INSTRUCTION-SET-ETERNAL-v1.md: RFC2307, SAMBA_INTERNAL DNS
# Trinity: Carter (programmable identity), Bauer (verify everything), Suehring (network first)
# Usage: Run as Administrator in PowerShell
# Prerequisites: Hyper-V enabled, Multipass installed
# Refs: wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller

# Configuration (GitOps declarative)
$VM_NAME = "rylan-dc-vm"
$VM_CPUS = 2
$VM_MEM = "4G"
$VM_DISK = "20G"
$UBUNTU_RELEASE = "noble"  # Ubuntu 24.04 LTS

# Samba AD/DC Parameters (non-interactive)
$DOMAIN = "rylan.internal"
$REALM = "RYLAN.INTERNAL"
$NETBIOS = "RYLAN"
$ADMIN_PASS = "Passw0rd123!"  # Complex password (rotate in production)
$DC_IP = "10.0.10.10"
$DC_GATEWAY = "10.0.10.1"
$DNS_FORWARDER = "1.1.1.1"  # Cloudflare; use "none" for air-gapped

Write-Output "=== Samba AD/DC Multipass Test (Non-Interactive) ==="
Write-Output "VM: $VM_NAME | Domain: $DOMAIN | IP: $DC_IP"

# Step 0: Pre-cleanup (idempotent - safe to re-run)
Write-Output "[0/8] Cleaning existing VM..."
if (multipass list | Select-String $VM_NAME) {
    multipass delete $VM_NAME --purge
    Write-Output "Existing VM purged for clean reproduction"
}

# Step 1: Launch VM with bridged network (internet access for apt)
Write-Output "[1/8] Launching VM with bridged network..."
try {
    multipass launch --name $VM_NAME `
        --cpus $VM_CPUS `
        --memory $VM_MEM `
        --disk $VM_DISK `
        --network name=Default Switch,mode=auto `
        $UBUNTU_RELEASE
    
    Start-Sleep -Seconds 5
    multipass info $VM_NAME
} catch {
    Write-Error "VM launch failed. Check Hyper-V and Multipass installation."
    exit 1
}

# Step 2: Configure static IP (simulate VLAN 10 servers network)
Write-Output "[2/8] Configuring static IP $DC_IP..."
$netplanConfig = @"
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - $DC_IP/24
      routes:
        - to: default
          via: $DC_GATEWAY
      nameservers:
        addresses: [$DC_IP, $DNS_FORWARDER]
"@

multipass exec $VM_NAME -- sudo bash -c "cat > /etc/netplan/01-netcfg.yaml << 'EOF'
$netplanConfig
EOF"
multipass exec $VM_NAME -- sudo netplan apply
Start-Sleep -Seconds 3

# Verify network
$ipCheck = multipass exec $VM_NAME -- ip addr show eth0
if ($ipCheck -notmatch $DC_IP) {
    Write-Error "Static IP assignment failed"
    exit 1
}
Write-Output "Static IP configured successfully"

# Step 3: Install Samba packages
Write-Output "[3/8] Installing Samba AD/DC packages..."
multipass exec $VM_NAME -- sudo apt update
multipass exec $VM_NAME -- sudo DEBIAN_FRONTEND=noninteractive apt install -y `
    samba winbind krb5-user python3-setproctitle `
    sssd sssd-ad attr acl smbclient ldap-utils

# Step 4: Pre-clean conflicting configs (prevents role conflict errors)
Write-Output "[4/8] Cleaning conflicting configurations..."
multipass exec $VM_NAME -- sudo systemctl stop smbd nmbd winbind 2>$null
multipass exec $VM_NAME -- sudo systemctl disable smbd nmbd winbind 2>$null
multipass exec $VM_NAME -- sudo rm -f /etc/samba/smb.conf
multipass exec $VM_NAME -- sudo rm -rf /var/lib/samba/*
multipass exec $VM_NAME -- sudo rm -rf /var/cache/samba/*

# Step 5: Provision AD/DC (NON-INTERACTIVE - all params scripted)
Write-Output "[5/8] Provisioning Samba AD/DC (non-interactive)..."
multipass exec $VM_NAME -- sudo samba-tool domain provision `
    --use-rfc2307 `
    --realm=$REALM `
    --domain=$NETBIOS `
    --server-role=dc `
    --dns-backend=SAMBA_INTERNAL `
    --adminpass="$ADMIN_PASS" `
    --option="dns forwarder = $DNS_FORWARDER"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Samba domain provision failed"
    exit 1
}
Write-Output "Domain provisioned successfully"

# Step 6: Configure Kerberos and DNS resolution
Write-Output "[6/8] Configuring Kerberos and DNS..."
multipass exec $VM_NAME -- sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

$resolvConfig = @"
search $DOMAIN
nameserver $DC_IP
nameserver $DNS_FORWARDER
"@
multipass exec $VM_NAME -- sudo bash -c "cat > /etc/resolv.conf << 'EOF'
$resolvConfig
EOF"

# Step 7: Start and enable Samba AD/DC service
Write-Output "[7/8] Starting Samba AD/DC service..."
multipass exec $VM_NAME -- sudo systemctl unmask samba-ad-dc
multipass exec $VM_NAME -- sudo systemctl start samba-ad-dc
multipass exec $VM_NAME -- sudo systemctl enable samba-ad-dc
Start-Sleep -Seconds 5

$serviceStatus = multipass exec $VM_NAME -- sudo systemctl is-active samba-ad-dc
if ($serviceStatus -ne "active") {
    Write-Error "Samba AD/DC service failed to start"
    multipass exec $VM_NAME -- sudo journalctl -u samba-ad-dc -n 50
    exit 1
}
Write-Output "Samba AD/DC service running"

# Step 8: Validation (shares, auth, DNS, Kerberos)
Write-Output "[8/8] Running validation tests..."

Write-Output "Test 1: SMB shares (sysvol/netlogon)"
multipass exec $VM_NAME -- smbclient -L localhost -N

Write-Output "Test 2: Authentication"
multipass exec $VM_NAME -- smbclient //localhost/netlogon -UAdministrator%"$ADMIN_PASS" -c 'ls'

Write-Output "Test 3: DNS SRV records"
multipass exec $VM_NAME -- host -t SRV _ldap._tcp.$DOMAIN

Write-Output "Test 4: Kerberos ticket"
multipass exec $VM_NAME -- bash -c "echo '$ADMIN_PASS' | kinit administrator@$REALM && klist"

Write-Output "Test 5: Domain level"
multipass exec $VM_NAME -- samba-tool domain level show

Write-Output ""
Write-Output "=== Validation Complete ==="
Write-Output "VM Name: $VM_NAME"
Write-Output "Domain: $DOMAIN ($REALM)"
Write-Output "DC IP: $DC_IP"
Write-Output "Admin: administrator@$REALM / $ADMIN_PASS"
Write-Output ""
Write-Output "Next Steps:"
Write-Output "1. Shell into VM: multipass shell $VM_NAME"
Write-Output "2. Test LDAP: ldapsearch -x -H ldap://$DC_IP -D 'cn=administrator,cn=users,dc=rylan,dc=internal' -w '$ADMIN_PASS' -b 'dc=rylan,dc=internal'"
Write-Output "3. Create test user: samba-tool user create testuser"
Write-Output "4. Join Windows client: Use $DC_IP as DNS, join domain $DOMAIN"
Write-Output "5. Cleanup when done: multipass delete $VM_NAME --purge"
Write-Output ""
Write-Output "The Fortress Never Sleeps. Validation RTO: <15 minutes."