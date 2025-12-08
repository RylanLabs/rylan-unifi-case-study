# IoT Connectivity Troubleshooting

**Audience:** Junior-at-3-AM deployable
**Scope:** Common IoT device connectivity issues and resolutions

---

## Issue 1: Denon HEOS Not Discovered by App

**Symptoms:**
- HEOS app shows "No devices found"
- Soundbar is online (LED shows network connection)
- Soundbar on VLAN 90, phone on VLAN 30

**Root Cause:** mDNS (multicast DNS) doesn't cross VLAN boundaries by default

### Solution: Verify mDNS Reflector

```bash
# Check mDNS reflector enabled on USG
ssh admin@$USG_IP "show configuration service mdns reflector"
# Expected output: reflector enable

# If missing, apply config
cd 02-declarative-config
python apply.py  # Re-applies config.gateway.json with mDNS

# Restart USG to ensure mDNS active
ssh admin@$USG_IP "reboot"
```

### Verification:

```bash
# From VLAN 30 (trusted-devices), scan for HEOS
avahi-browse -a -t | grep -i heos
# Expected: _heos._tcp local

# If still not visible, check firewall
ssh admin@$USG_IP "show firewall statistics"
# Look for dropped mDNS packets (UDP 5353)
```

### Alternative: Manual IP Entry

```bash
# In HEOS app → Settings → Advanced → Manual IP Entry
# Enter soundbar IP: 10.0.90.XXX (from DHCP leases)
```

---

## Issue 2: Traeger Grill Offline After Network Change

**Symptoms:**
- Traeger app shows "Grill offline"
- Grill WiFi connected (LED solid blue)
- UniFi shows device on VLAN 95

**Root Cause:** Firewall blocking required cloud ports

### Solution: Verify Firewall Rules

```bash
# Check policy table has IoT-Isolated rule
python guardian/audit-eternal.py
# Expected: 9/10 rules, including "IoT-Isolated → Internet (Whitelist)"

# Verify ports 443 + 8883 allowed
grep -A5 "iot-isolated" 02-declarative-config/policy-table.yaml
# Expected: ports: ["443", "8883"]

# Check USG firewall logs
ssh admin@$USG_IP "show log firewall" | grep 10.0.95
# Look for BLOCKED packets to traeger-cloud.io
```

### Verification:

```bash
# From VLAN 95 (difficult without shell access), use UniFi DPI
# Navigate to: UniFi Controller → Insights → Deep Packet Inspection
# Filter: VLAN 95, Destination: traeger-cloud.io
# Expected: HTTPS (443) + MQTT (8883) traffic allowed
```

### Alternative: Factory Reset Traeger

```bash
# Hold ignite button 10 seconds until LED flashes
# Re-pair via Traeger app
# Ensure phone on "IoT-Isolated" WiFi during pairing
```

---

## Issue 3: Printer Not Reachable from Workstation

**Symptoms:**
- `ping 10.0.30.50` times out
- Printer shows as "Offline" in CUPS
- Printer has valid IP in DHCP leases

**Root Cause:** Workstation on wrong VLAN or printer IP changed

### Solution: Verify VLAN Assignment

```bash
# Check workstation VLAN (should be VLAN 30)
ip addr show | grep inet
# Expected: 10.0.30.XXX

# Check printer DHCP lease in UniFi Controller
# Navigate to: Clients → Printer → Details
# Verify IP matches configured printer IP (10.0.30.50)

# If IP changed, update printer static IP or CUPS
sudo lpadmin -p printer01 -v socket://10.0.30.<NEW_IP>:9100
```

### Verification:

```bash
# Test raw socket connection
nc -zv 10.0.30.50 9100
# Expected: Connection to 10.0.30.50 9100 port [tcp/*] succeeded!

# Test print
echo "Test page $(date)" | lp -d printer01
```

---

## Issue 4: IoT Device Firmware Update Failing

**Symptoms:**
- Denon/Traeger reports "Update failed"
- Device shows available firmware in app
- Internet connectivity confirmed (can browse from device)

**Root Cause:** OTA update server uses non-standard port blocked by firewall

### Solution: Identify Required Ports

```bash
# Capture traffic during update attempt
ssh admin@$USG_IP
sudo tcpdump -i eth0.90 -n port not 22 -w /tmp/denon-update.pcap

# Transfer pcap to workstation
scp admin@$USG_IP:/tmp/denon-update.pcap .

# Analyze with tshark
tshark -r denon-update.pcap -T fields -e ip.dst -e tcp.dstport | sort -u
# Identify blocked destination ports

# Add port to policy-table.yaml if legitimate
```

### Temporary Workaround:

```bash
# Temporarily move device to VLAN 30 (trusted-devices)
# In UniFi Controller:
# 1. Identify device by MAC
# 2. Settings → Network → Override to VLAN 30
# 3. Perform firmware update
# 4. Revert to VLAN 90 after update completes
```

---

## Issue 5: High Latency on IoT VLAN

**Symptoms:**
- Denon streaming stutters or buffers
- Traeger app commands delayed (5-10s)
- USG CPU high (>80%)

**Root Cause:** USG-3P hardware offload bypassed (too many VLANs or rules)

### Solution: Check Hardware Offload Status

```bash
# Monitor USG CPU
ssh admin@$USG_IP "top -b -n 1 | grep 'CPU:'"
# Expected: <80% (ADR-015 target)

# Check VLAN count
ip link show | grep '@' | wc -l
# Expected: 7 VLANs (within ADR-015 limit)

# Check firewall rule count
python -c "import yaml; print(len(yaml.safe_load(open('02-declarative-config/policy-table.yaml'))['rules']))"
# Expected: 9 rules (within ≤10 limit)
```

### Mitigation:

```bash
# If CPU consistently >80%:
# 1. Consolidate VLANs (merge guest-iot 90 + iot-isolated 95)
# 2. Reduce firewall rules (consolidate ports)
# 3. Upgrade to UDM-Pro (future v∞.3.x)

# Immediate: Disable DPI on USG
ssh admin@$USG_IP
configure
set system offload ipv4 forwarding enable
commit ; save ; exit

# Verify offload re-enabled
show system offload
# Expected: ipv4: enabled
```

---

## Issue 6: mDNS Reflector Not Working After USG Reboot

**Symptoms:**
- HEOS discovery fails after USG restart
- `show configuration service mdns reflector` shows "enable"
- Avahi-browse shows no cross-VLAN devices

**Root Cause:** config.gateway.json not provisioned from controller

### Solution: Force Controller Provision

```bash
# Re-provision USG from UniFi Controller
# In UniFi Controller:
# 1. Devices → USG → Settings → Manage Device
# 2. Click "Force Provision"
# 3. Wait 60s for config push

# Verify mDNS process running
ssh admin@$USG_IP "ps aux | grep mdns"
# Expected: /usr/sbin/mdnsd process active

# Restart mDNS service if needed
ssh admin@$USG_IP "sudo /etc/init.d/mdns restart"
```

---

## Diagnostic Commands Cheat Sheet

```bash
# Check VLAN assignment
ssh admin@$USG_IP "show interfaces"

# Check DHCP leases
ssh admin@$USG_IP "show dhcp leases"

# Check firewall hit counts
ssh admin@$USG_IP "show firewall statistics"

# Monitor real-time traffic
ssh admin@$USG_IP "sudo tcpdump -i eth0.90 -n"

# Check mDNS across VLANs
avahi-browse -a -t  # From trusted-devices VLAN 30

# Validate policy table
python guardian/audit-eternal.py

# Check USG hardware offload
ssh admin@$USG_IP "show system offload"
```

---

## Escalation Path

If issue persists after troubleshooting:

1. **Check ADRs**: Review ADR-013 (segmentation), ADR-015 (VLAN limits)
2. **Review logs**: `docs/validation/VALIDATION-REPORT.md` for baseline
3. **Run orchestrator**: `bash 03-validation-ops/orchestrator.sh --verbose`
4. **GitHub issue**: File with logs, tcpdumps, exact error messages
5. **Nuke/resurrect**: Last resort — `docs/runbooks/nuke-resurrect-v∞.1.md`

---

## References
- ADR-013: IoT segmentation strategy
- ADR-015: VLAN expansion limits (CPU <80%)
- Runbook: docs/runbooks/iot-onboarding.md
- Trinity: Bauer (verify everything) + Suehring (network perimeter)
