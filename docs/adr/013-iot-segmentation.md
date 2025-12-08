# ADR-013: IoT Device Segmentation Strategy

**Status:** Accepted
**Date:** 2025-12-04
**Context:** v∞.1.2-iot-ready — Adding Traeger grill, Denon HEOS soundbars, and printer to fortress

## Context

The fortress requires integration of four IoT devices with varying trust levels:
1. **Traeger pellet grill** — High cloud dependency, WiFi-only, untrusted manufacturer
2. **Denon HEOS E300/E400 soundbars** — Moderate cloud dependency, hardwired capable, semi-trusted
3. **Network printer** — No cloud dependency, legacy device, low risk

 Existing VLANs: 10 (servers), 30 (trusted-devices), 40 (voip), 90 (guest-iot)
 
 ## Decision
 
 Implement **two-tier IoT segmentation** with new VLANs:
 
 - **VLAN 95 (iot-isolated)**: Untrusted WiFi IoT devices (Traeger)
   - Subnet: 10.0.95.0/24
   - Internet-only access via firewall whitelist (ports 443, 8883)
   - Zero local network access
   - DNS: Public resolvers only (1.1.1.1, 1.0.0.1)
 
 - **VLAN 90 (guest-iot)**: Preferred placement for semi-trusted hardwired IoT (Denon)
   - Subnet: 10.0.90.0/24
   - Internet access for streaming services (ports 80, 443)
   - mDNS reflector optional (avoid where possible)
   - DNS: Public resolvers or Pi-hole forwarding
   - Requires physical ethernet connection (US-8 Port 2) with MAC/port binding

 **Total VLANs: 6** (Management + 5 custom)

## Alternatives Considered

1. **Single IoT VLAN (rejected)**: Mixing untrusted (Traeger) with semi-trusted (Denon) violates zero-trust principle
2. **Traeger on existing guest-iot VLAN 90 (rejected)**: VLAN 90 is broader "guest" scope; VLAN 95 provides explicit Traeger isolation
3. **Denon on trusted-devices VLAN 30 (rejected)**: Violates segmentation principle; streaming cloud access shouldn't touch AD/NFS servers

## Consequences

### Positive
- **Defense in depth**: Traeger compromise cannot pivot to Denon or trusted devices
- **Suehring compliance**: Network perimeter enforced via firewall rules
- **Bauer compliance**: Explicit whitelist (443, 8883) prevents lateral movement
- **Carter compliance**: Device identity tracked in shared/inventory.yaml

### Negative
- **VLAN sprawl**: 6 total VLANs (1, 10, 30, 40, 90, 95)
- **Firewall rules**: Adds 2 rules (total 9/10 — safe for USG-3P offload)
- **Management overhead**: Separate DHCP pools, DNS configs, monitoring

### Mitigation
- Lock VLAN count at 6 (see ADR-015)
- Monitor USG-3P CPU via orchestrator.sh (target <80%)
- Document onboarding procedure (docs/runbooks/iot-onboarding.md)

## References
- Trinity: Suehring (2005) — "Network is first line of defense"
- Phase 3 endgame: Hardware offload preserved (≤10 firewall rules)
- ADR-015: VLAN expansion limits for USG-3P
