# IoT Device Onboarding Runbook — v∞.1.2

**Purpose:** Step-by-step procedures for onboarding Traeger, Denon, and Printer to fortress
**Audience:** Junior-at-3-AM deployable
**Prerequisites:** VLANs 95 and 90 configured, mDNS reflector enabled, policy table applied

---

## Pre-Onboarding Checklist

1. **Verify network readiness**:

   ```bash
   # Check VLANs exist
   ssh admin@$USG_IP "show interfaces"
   # Expected: eth0.95 (10.0.95.1), eth0.90 (10.0.90.1)

   # Check firewall rules
   python 02-declarative-config/apply.py --dry-run
   # Expected: 9 rules total, including IoT rules 8-9

   # Check mDNS reflector
   ssh admin@$USG_IP "show configuration service mdns reflector"
   # Expected: reflector enable
   ```

2. **Update inventory placeholders**: Record MAC addresses in `shared/inventory.yaml` during Week 1

---

## Device 1: Traeger Pellet Grill

**VLAN:** 95 (iot-isolated)
**Connection:** WiFi only
**Ports allowed:** 443 (HTTPS), 8883 (MQTT over TLS)

### Step 1: Configure WiFi for VLAN 95

```bash
# In UniFi Controller
1. Navigate to Settings → Networks → iot-isolated
2. Verify VLAN ID = 95, DHCP enabled (10.0.95.100-200)
3. Create WiFi SSID: "IoT-Isolated"
   - Security: WPA2-PSK (strong passphrase)
   - Network: iot-isolated (VLAN 95)
   - Guest Policy: Enabled (hide from other networks)
```

### Step 2: Connect Traeger

```bash
1. Factory reset Traeger (hold ignite button 10s)
2. Open Traeger app → Add Device
3. Connect phone to "IoT-Isolated" WiFi
4. Follow app pairing (connects to traeger-cloud.io)
5. Verify connectivity: Check app shows grill temp
```

### Step 3: Verify Isolation

```bash
# From Traeger VLAN 95, should FAIL to ping servers
ssh admin@$USG_IP
ping 10.0.10.10  # Should timeout (Pi-hole blocked)
ping 10.0.30.1   # Should timeout (trusted-devices blocked)

# Should SUCCEED internet
ping 1.1.1.1
curl https://traeger-cloud.io  # Should succeed
```

### Step 4: Update Inventory

```yaml
# shared/inventory.yaml
- device_name: "Traeger Pellet Grill"
  mac_address: "<RECORDED_MAC>"
  ip_current: "10.0.95.XXX"
  firmware_version: "<FROM_APP>"
```

---

## Device 2: Denon HEOS E300/E400 Soundbars

**VLAN:** 90 (guest-iot)
**Connection:** Hardwired (US-8 Port 2)
**Ports allowed:** 80 (HTTP), 443 (HTTPS), 1900 (UPnP), 8009 (HEOS)

### Step 1: Configure US-8 Port 2

```bash
# In UniFi Controller
1. Navigate to Devices → US-8 → Ports → Port 2
2. Set Profile: iot_isolated
   - Native VLAN: 90
   - PoE: Auto (not required but safe)
   - Storm Control: Enabled
   - STP: RSTP
3. Apply Changes
```

### Step 2: Connect Ethernet Cable

```bash
1. Run Cat6 ethernet from US-8 Port 2 to soundbar
2. Soundbar will DHCP on VLAN 90 (10.0.90.100-200)
3. Check DHCP leases in UniFi Controller
   - Expected: Denon device appears with MAC
```

### Step 3: Configure HEOS App

```bash
1. Download HEOS app (phone on VLAN 30 trusted-devices)
2. App should discover soundbar via mDNS reflector
3. If discovery fails, see Troubleshooting → mDNS
4. Complete setup, link Spotify/Pandora accounts
5. Test playback from streaming services
```

### Step 4: Verify Connectivity

```bash
# mDNS discovery test
avahi-browse -a -t | grep HEOS
# Expected: _heos._tcp local

# Check internet access (from VLAN 90)
curl -I https://heos.denon.com
# Expected: HTTP 200

# Verify no server access
nc -zv 10.0.10.10 22  # SSH to Pi-hole should timeout
```

### Step 5: Update Inventory

```yaml
# shared/inventory.yaml (repeat for E300 and E400)
- device_name: "Denon HEOS E300 Soundbar"
   mac_address: "<US8_PORT2_MAC>"
   ip_current: "10.0.90.XXX"
   connection_type: "Hardwired US-8 Port 2 (VLAN 90 guest-iot)"
```

---

## Device 3: Network Printer

**VLAN:** 30 (trusted-devices) — legacy device, low risk
**Connection:** WiFi or hardwired
**Ports allowed:** 9100 (RAW), 515 (LPD), 631 (IPP)

### Step 1: Connect Printer

```bash
# WiFi option
1. Connect printer to "Trusted-Devices" WiFi (VLAN 30)
2. Configure static IP in printer settings (10.0.30.50 recommended)
3. Set DNS to 10.0.10.10 (Pi-hole)

# Hardwired option
1. Connect to US-8 Port X (set native VLAN 30)
2. Printer DHCP assigns 10.0.30.XXX
```

### Step 2: Configure Print Server

```bash
# Linux workstation (VLAN 30)
sudo apt install cups
sudo lpadmin -p printer01 -v socket://10.0.30.50:9100 -m everywhere
sudo lpoptions -d printer01

# Test print
echo "Test page" | lp -d printer01
```

### Step 3: Update Inventory

```yaml
# shared/inventory.yaml
- device_name: "Network Printer"
  mac_address: "<PRINTER_MAC>"
  ip_current: "10.0.30.50"
  connection_type: "WiFi (VLAN 30 trusted-devices)"
```

---

## Post-Onboarding Validation

Run full fortress validation suite:

```bash
# 1. Policy table audit
python guardian/audit-eternal.py
# Expected: 9/10 rules, offload safe

# 2. Network isolation test
bash 03-validation-ops/validate-isolation.sh
# Expected: VLAN 95/90 isolated from servers

# 3. mDNS reflector test
avahi-browse -a -t  # From VLAN 30
# Expected: Denon HEOS devices visible

# 4. Backup verification
bash 03-validation-ops/orchestrator.sh --test-restore
# Expected: RTO <15 min
```

---

## References
- ADR-013: IoT segmentation rationale
- ADR-015: VLAN expansion limits
- Troubleshooting: docs/troubleshooting/iot-connectivity.md
- Nuke/resurrect: docs/runbooks/nuke-resurrect-v∞.1.md
