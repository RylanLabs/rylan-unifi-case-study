# Network Configuration Troubleshooting

## NIC Not Detected

**Symptom**: `eternal-resurrect.sh` fails with "No ethernet NIC found (expected en*, eth*)"

### Diagnosis

Check available network interfaces:

```bash
ip -o link show
```

Verify naming scheme:
- **Systemd predictable naming** (modern): `eno1`, `enp3s0`, `enp4s0`, etc.
- **Legacy naming**: `eth0`, `eth1`, etc.
- **Virtual/Bridged** (skip): `vlan*`, `docker*`, `br-*`, `veth*`

### Root Causes

| Cause | Impact | Fix |
|-------|--------|-----|
| Only loopback interface detected | Network completely unavailable | Check BIOS/UEFI settings, verify hardware |
| NIC using legacy naming (eth*) only | Script skips non-en* interfaces | Update match pattern in netplan config |
| Multiple NICs, first one inactive | Wrong NIC selected | Ensure primary NIC is enabled |
| VM network adapter misconfigured | DHCP/static config fails | Restart VM, check hypervisor settings |

### Fix Options

#### Option 1: Update Netplan Match Pattern (Recommended)

Edit `bootstrap/netplan-rylan-dc.yaml`:

```yaml
ethernets:
  primary-nic:
    match:
      name: "eth*"  # For legacy naming
      # OR
      name: "en*"   # For systemd predictable naming
      # OR explicit match
      name: "enp3s0"  # For specific NIC
```

Then re-run:

```bash
./eternal-resurrect.sh
```

#### Option 2: Manual Interface Selection

Find your primary interface:

```bash
ip -o link show | awk -F': ' '{print $2}' | grep -E "^en|^eth" | grep -v vlan | head -1
```

Apply netplan manually:

```bash
sudo cp bootstrap/netplan-rylan-dc.yaml /etc/netplan/99-rylan-dc.yaml
sudo sed -i 's/primary-nic/YOUR_NIC_NAME/g' /etc/netplan/99-rylan-dc.yaml
sudo netplan apply --debug
```

#### Option 3: Verify Hardware Availability

Check physical NIC status:

```bash
# Detailed hardware info
lshw -C network

# Or simpler view
nmtui  # NetworkManager TUI (if available)
```

Enable NIC if needed:

```bash
sudo ip link set YOUR_NIC_NAME up
sudo dhclient YOUR_NIC_NAME  # Test DHCP
```

---

## IP Address Not Assigned

**Symptom**: Netplan applies without errors, but `10.0.10.10` or `10.0.30.10` not present

### Diagnosis

Verify current IP state:

```bash
ip addr show
```

Check netplan configuration:

```bash
sudo netplan --debug generate
```

Review systemd-networkd logs:

```bash
sudo journalctl -u systemd-networkd -n 50
```

### Root Causes

| Cause | Symptom | Fix |
|-------|---------|-----|
| Route gateway unreachable | Primary IP assigned but no connectivity | Verify gateway `10.0.10.1` exists |
| DNS not working | IP assigned but DNS queries fail | Check nameserver `127.0.0.1` (Samba DNS) |
| VLAN tag mismatch | VLAN 30 IP not assigned | Verify VLAN 30 configured on switch/interface |
| netplan.io not installed | Apply command fails silently | `sudo apt install netplan.io` |

### Fix Options

#### Option 1: Reapply Netplan with Debug

```bash
sudo netplan apply --debug
sleep 2
ip addr show
```

#### Option 2: Manual IP Assignment (Temporary)

```bash
# Primary IP
sudo ip addr add 10.0.10.10/26 dev YOUR_NIC_NAME
sudo ip route add default via 10.0.10.1 dev YOUR_NIC_NAME

# VLAN 30 (if needed)
sudo ip link add link YOUR_NIC_NAME name YOUR_NIC_NAME.30 type vlan id 30
sudo ip link set YOUR_NIC_NAME.30 up
sudo ip addr add 10.0.30.10/24 dev YOUR_NIC_NAME.30
```

Then persist in netplan by fixing `bootstrap/netplan-rylan-dc.yaml` and running:

```bash
./eternal-resurrect.sh
```

#### Option 3: Verify Gateway/Samba DC Connectivity

```bash
# Ping gateway
ping -c 3 10.0.10.1

# Test DNS (once Samba DNS is running)
nslookup rylan.internal 127.0.0.1
```

---

## Netplan Configuration Validation

### Pre-deployment Check

Validate syntax before applying:

```bash
sudo netplan --debug generate
```

Should output:

```
Generated config: /run/systemd/network/10-netplan-primary-nic.network
Generated config: /run/netplan-primary-nic.30.network
```

### Dry-Run Network Application

Test without restarting network:

```bash
sudo netplan apply --debug
```

Monitor with:

```bash
sudo journalctl -f -u systemd-networkd
```

### Rollback to DHCP

If static config causes connectivity loss:

```bash
sudo rm /etc/netplan/99-rylan-dc.yaml
sudo netplan apply
```

---

## VLAN 30 (PXE) Configuration

### Verify VLAN Sub-Interface

```bash
ip -d link show | grep -A 2 vlan

# Example output:
# 5: YOUR_NIC_NAME.30@YOUR_NIC_NAME: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group 32
#     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff promiscuity 0 
#     vlan protocol 802.1q id 30 <REORDER_HDR> txqueuelen 1000
```

### Test PXE Service IP

```bash
# Check if 10.0.30.10 is listening
netstat -tln | grep 10.0.30.10

# Or verify with ip
ip addr show | grep 10.0.30.10
```

### Troubleshoot VLAN Not Tagged

If VLAN sub-interface not created:

1. **Check netplan syntax** (no typos in vlan section)
2. **Verify link reference** matches primary-nic name
3. **Re-apply netplan**:

```bash
sudo netplan apply --debug
sleep 2
ip addr show
```

---

## Carter Principle: Programmable Infrastructure

All network configuration is **declarative and reproducible**:

- ✅ Hardware names detected programmatically (`en*`, `eth*`, etc.)
- ✅ No hardcoded interface names in production
- ✅ VLAN config auto-applies via netplan
- ✅ Rollback to DHCP is one-line removal

This ensures junior deployments work on **Intel NUCs, AMD systems, Multipass VMs, and bare-metal servers** without manual intervention.

---

## References

- **Netplan Documentation**: https://netplan.readthedocs.io/en/latest/netplan-yaml/
- **Systemd Predictable Naming**: https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/
- **ArchWiki Network Config**: https://wiki.archlinux.org/title/Network_configuration
- **Netplan Examples**: https://netplan.readthedocs.io/en/stable/examples/
