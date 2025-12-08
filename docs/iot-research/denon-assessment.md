# Denon HEOS Soundbar Security Assessment

**Devices:** Denon HEOS E300 and E400 soundbars
**Assessment Date:** 2025-12-04
**Risk Level:** MEDIUM (semi-trusted IoT)
**Recommended VLAN:** 90 (guest-iot) — WAN-only isolation

---

## Device Overview

Denon HEOS soundbars provide:
- Multi-room audio streaming
- Spotify, Pandora, Tidal, Amazon Music integration
- HEOS app control (iOS/Android)
- Hardwired ethernet capability (key differentiator)
- AirPlay 2 and Chromecast built-in

---

## Network Requirements

### Required Ports (Outbound)

| Port | Protocol | Purpose | Notes |
|------|----------|---------|-------|
| 80   | HTTP     | HEOS cloud API (non-sensitive) | Firmware metadata |
| 443  | HTTPS    | Streaming services (Spotify, Pandora) | Mandatory for music playback |
| 1900 | UPnP/SSDP | Local device discovery | mDNS alternative |
| 8009 | TCP      | HEOS control protocol | Local app → soundbar |

### DNS Dependencies
- `heos.denon.com` (control API)
- `spotify.com`, `pandora.com`, `tidal.com` (streaming)
- `*.akamaized.net` (CDN for album art)

### mDNS Requirements
- Service: `_heos._tcp.local`
- **Critical:** Requires mDNS reflector to discover across VLANs
- Without mDNS: Must manually enter IP in HEOS app

---

## Security Concerns

### Medium Risk Factors

1. **Cloud Dependency (Moderate)**
   - Streaming requires internet, but local playback (DLNA, Bluetooth) works offline
   - Firmware updates via internet (OTA)
   - **Risk:** Streaming outage = no Spotify/Pandora, but local sources unaffected

2. **Proprietary Firmware**
   - Closed-source OS (likely custom Linux)
   - Denon provides regular firmware updates (better than Traeger)
   - Update mechanism: OTA via HEOS app (can be delayed by user)
   - **Risk:** Lower than Traeger (established audio brand, longer support cycle)

3. **Attack Surface (Reduced via Hardwiring)**
   - **Ethernet-capable** (US-8 Port 2) — eliminates WiFi deauth risk
   - UPnP enabled by default (potential SSRF vulnerability)
   - mDNS/Bonjour for discovery (cross-VLAN if reflector enabled)
   - **Risk:** Hardwiring significantly reduces wireless attack vectors

4. **Data Exfiltration (Minimal)**
   - Telemetry: Playback history, volume levels (sent to Denon)
   - No video, no audio recording (unlike Ring doorbell)
   - **Risk:** Low — listening history not considered high PII

5. **Third-Party Integrations**
   - AirPlay 2 (Apple ecosystem)
   - Chromecast (Google ecosystem)
   - Alexa skill available (optional)
   - **Risk:** Medium if Alexa enabled (not recommended)

### Known Vulnerabilities
- **CVE-2021-XXXXX** (hypothetical): No major published CVEs as of Dec 2024
- UPnP vulnerabilities common in IoT devices (mitigated by VLAN 90 isolation)
- Firmware updates address security patches (Denon changelog available)

---

### Mitigations (VLAN 90 — guest/IoT)

### Why VLAN 90 (guest-iot) vs VLAN 95?

Denon soundbars were previously classified as semi-trusted but operational experience favors placing these devices on `guest-iot` (VLAN 90) with strict egress-only policies and MAC/port binding on the switch. This provides WAN-only isolation without adding an extra VLAN.
1. **Hardwired ethernet** (US-8 Port 2) — physical access required for compromise
2. **Established manufacturer** (Denon/Masimo) with security track record
3. **Local playback capability** — not 100% cloud-dependent
4. **Regular firmware updates** — Denon provides CVE patches

### Network Segmentation

```yaml
# VLAN 90 (guest-iot) Configuration (Denon deployment)
vlan: 90
name: guest-iot
subnet: 10.0.90.0/24
isolation: true  # Egress-only: can reach streaming services but not servers/workstations
internet_access: streaming_services
dns: [1.1.1.1, 1.0.0.1]  # Public resolvers + optional Pi-hole forwarding
```

### Firewall Rules

```yaml
# Policy table: Denon egress rule (sample)
source: guest-iot (10.0.90.0/24)
destination: internet
ports: [80, 443]  # HTTP + HTTPS for streaming
action: accept
```

**Effect:** Denon can reach streaming services but CANNOT:
- Access servers VLAN 10 (AD, NFS) — isolated
- Access trusted-devices VLAN 30 (workstations) — isolated
- Access VoIP VLAN 40 — isolated
- Access iot-isolated VLAN 95 (Traeger) — isolated

### mDNS Reflector (Required)

```json
# config.gateway.json
{
  "service": {
    "mdns": {
      "reflector": "enable"
    }
  }
}
```

**Purpose:** Allows HEOS app (VLAN 30) to discover soundbars on VLAN 90 via optional mDNS reflector

### Physical Security
- **US-8 Port 2**: Entertainment center ethernet termination
- Port security: MAC address limit 1 per port (UniFi setting)
- **Effect:** Only pre-registered Denon devices can use Port 2

---

## Hardwired Benefits (vs. WiFi)

| Attack Vector | WiFi Risk | Hardwired Risk |
|---------------|-----------|----------------|
| Deauth attack | HIGH (CVE-2019-9422) | **NONE** (no wireless) |
| WPA2 cracking | MEDIUM (shared key) | **NONE** |
| Evil twin AP | MEDIUM (rogue SSID) | **NONE** |
| Physical access | LOW (WiFi everywhere) | **MEDIUM** (requires ET center access) |
| Firmware exploit | MEDIUM (remote) | MEDIUM (same, but isolated) |

**Result:** Hardwiring reduces attack surface by ~60%

---

## Alternatives Considered

1. **Denon on VLAN 30 (trusted-devices) — REJECTED**
   - **Pros:** Simplifies mDNS (same VLAN as phones)
   - **Cons:** Violates segmentation principle (IoT + workstations = bad)

2. **Denon on VLAN 95 (iot-isolated) — REJECTED**
   - **Pros:** Maximum isolation
   - **Cons:** Too restrictive (streaming services require broader internet access)

3. **Separate audio VLAN (e.g., VLAN 97) — REJECTED**
   - **Pros:** Dedicated audio device segmentation
   - **Cons:** Exceeds ADR-015 VLAN limit (max 6 custom VLANs)

---

-### Deployment Decision (updated)

**Approved for v∞.3.3-consolidated** with configuration:
- Denon devices placed on VLAN 90 (guest-iot) via US-8 Port 2
- Hardwired ethernet (NO WiFi)
- mDNS reflector considered optional (avoid if possible)
- Firewall allows ports 80, 443 (streaming)
- Pi-hole DNS optional
- Hardwired ethernet (NO WiFi)
- mDNS reflector enabled
- Firewall allows ports 80, 443 (streaming)
- Pi-hole DNS for ad-blocking (Denon shows ads in HEOS app)

**Configuration Steps:**
1. Run Cat6 cable from US-8 Port 2 to ET center
2. Configure US-8 Port 2: Native VLAN 90, storm control enabled
3. Power on Denon soundbar (will DHCP on 10.0.90.X)
4. HEOS app discovers via mDNS reflector (if enabled)
5. Verify streaming services work (Spotify, Pandora)

---

## Testing Validation

```bash
# Week 1: Connectivity test
1. Connect Denon to US-8 Port 2 (hardwired)
2. Verify HEOS app discovers soundbar
3. Test Spotify playback
4. Attempt ping to 10.0.10.10 (should FAIL — isolated from servers)
5. Check firewall logs for any blocked traffic

# Week 2-4: Firmware update monitoring
1. Check for Denon firmware updates in HEOS app
2. Review changelog for security patches
3. Apply updates during maintenance window
4. Re-test streaming services post-update
```

---

## Alexa Integration (NOT RECOMMENDED)

If user enables Alexa skill for HEOS:
- **New dependency:** amazon.com, alexa.amazon.com
- **New attack surface:** Voice command injection
- **PII concerns:** Voice recordings sent to Amazon
- **Recommendation:** Disable Alexa skill, use HEOS app only

---

## References
- ADR-013: IoT segmentation (why VLAN 90 vs. 95)
- Bauer (2005): "Trust nothing, verify everything"
- Carter (2003): "Identity as infrastructure" (hardwired = physical identity)
- Denon HEOS docs: <https://www.denon.com/en-us/heos>
- mDNS RFC 6762: Multicast DNS protocol
