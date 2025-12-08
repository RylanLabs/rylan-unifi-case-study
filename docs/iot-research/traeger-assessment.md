# Traeger Pellet Grill Security Assessment

**Device:** Traeger WiFire-enabled pellet grill
**Assessment Date:** 2025-12-04
**Risk Level:** HIGH (untrusted IoT)
**Recommended VLAN:** 95 (iot-isolated)

---

## Device Overview

Traeger pellet grills with WiFire technology provide:
- Remote temperature monitoring via mobile app
- Cloud-based recipe integration
- Firmware OTA updates
- Alexa/Google Assistant integration (optional)

---

## Network Requirements

### Required Ports (Outbound)

| Port | Protocol | Purpose | Notes |
|------|----------|---------|-------|
| 443  | HTTPS    | Cloud API (traeger-cloud.io) | Mandatory for app connectivity |
| 8883 | MQTT/TLS | Real-time telemetry | Temperature/status updates |
| 123  | NTP      | Time synchronization | Optional but recommended |

### DNS Dependencies
- `traeger-cloud.io` (primary API)
- `mqtt.traeger.com` (telemetry)
- `api.traeger.com` (firmware updates)
- `*.amazonaws.com` (AWS backend)

---

## Security Concerns

### High Risk Factors

1. **Mandatory Cloud Dependency**
   - Cannot function offline (requires internet for app control)
   - All commands routed through Traeger servers (not local control)
   - **Risk:** Single point of failure, outage = no remote control

2. **Proprietary Firmware**
   - Closed-source OS (likely embedded Linux)
   - No security audit publicly available
   - Update mechanism: OTA via cloud (cannot be disabled)
   - **Risk:** Potential backdoors, unpatched vulnerabilities

3. **Attack Surface**
   - WiFi-only (no hardwired option)
   - WPA2-PSK authentication (shared key = single compromise point)
   - mDNS/Bonjour for local discovery
   - **Risk:** WiFi deauth attacks, man-in-the-middle

4. **Data Exfiltration**
   - Telemetry: Temperature, cook times, grill location (via WiFi geolocation)
   - Usage patterns sent to Traeger servers
   - No opt-out for telemetry
   - **Risk:** Bauer compliance failure (PII leakage via usage data)

5. **Third-Party Integrations**
   - Alexa/Google Assistant optional but documented
   - IFTTT webhooks supported
   - **Risk:** Expands attack surface if enabled

### Known Vulnerabilities
- **CVE-2019-XXXXX** (hypothetical): No published CVEs as of Dec 2024
- Community reports of WiFi credential exposure in firmware dumps (unverified)
- Firmware version tracking poor (app doesn't display CVE patch status)

---

## Mitigations (VLAN 95 Isolation)

### Network Segmentation

```yaml
# VLAN 95 Configuration
vlan: 95
name: iot-isolated
subnet: 10.0.95.0/24
isolation: true  # Cannot access VLANs 10, 30, 40, 90
internet_access: whitelist_only
```

### Firewall Rules (Whitelist)

```yaml
# Policy table rule 8
source: iot-isolated (10.0.95.0/24)
destination: internet
ports: [443, 8883]  # HTTPS + MQTT/TLS only
action: accept
```

**Effect:** Traeger can reach cloud services but CANNOT:
- Access servers VLAN 10 (AD, NFS, Pi-hole)
- Access trusted-devices VLAN 30 (workstations)
- Access VoIP VLAN 40
- Pivot to other IoT devices VLAN 90

### DNS Restrictions
- DNS servers: 1.1.1.1, 1.0.0.1 (public only, NO Pi-hole)
- **Rationale:** Pi-hole on VLAN 10 servers — isolation prevents DNS query logging

### Monitoring (Future v∞.2.x)
- Pi-hole DNS sinkhole for `traeger-cloud.io` (block if compromised)
- Loki log aggregation for Traeger traffic patterns
- Alert on unexpected destination IPs (non-Traeger domains)

---

## Alternatives Considered

1. **Local-only BBQ controller (recommended for v∞.3.x)**
   - Example: ThermoWorks Signals (no cloud, Bluetooth only)
   - **Pros:** No internet required, zero cloud dependency
   - **Cons:** No remote monitoring when away from home

2. **Traeger + Raspberry Pi proxy (rejected)**
   - Bridge Traeger traffic through Pi with packet inspection
   - **Pros:** Could log/filter traffic locally
   - **Cons:** Complexity high, breaks Traeger warranty, still cloud-dependent

3. **Firmware replacement (rejected)**
   - Flash custom firmware (if possible)
   - **Pros:** Full control, no Traeger cloud
   - **Cons:** Likely impossible (signed firmware), voids warranty

---

## Deployment Decision

**Approved for v∞.1.2** with restrictions:
- VLAN 95 (iot-isolated) **ONLY**
- Firewall whitelist ports 443, 8883
- No Alexa/Google Assistant integration
- Monitor for 30 days, review telemetry patterns

**Future Action (v∞.2.x):**
- Evaluate ThermoWorks Signals or Fireboard as Traeger replacement
- If keeping Traeger, add Loki alerting for anomalous traffic

---

## Testing Validation

```bash
# Week 1: Connectivity test
1. Connect Traeger to IoT-Isolated WiFi
2. Verify app shows grill online
3. Attempt ping to 10.0.10.10 (should FAIL)
4. Monitor firewall logs for blocked traffic

# Week 2-4: Usage monitoring
1. Log all Traeger outbound connections (tcpdump)
2. Identify any non-Traeger domains contacted
3. Check for unexpected ports (alert if not 443/8883)
```

---

## References
- ADR-013: IoT segmentation rationale (VLAN 95 isolation)
- ADR-014: Ring exclusion (similar cloud dependency concerns)
- Bauer (2005): "Trust nothing, verify everything"
- Traeger WiFire docs: <https://www.traeger.com/wifire>
