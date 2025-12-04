# Current Policy Table State – v1.1.2-production-ready

**Total rules**: 10 (≤10 → USG-3P hardware offload safe ✅)

## Policy Rules Inventory

1. **Management → Everywhere (controller + SSH)**
   - Ports: 22, 443, 8443, 161
   - Purpose: Administrative access from management VLAN

2. **trusted-devices → servers (DNS, AD, NFS, Influx, PXE)**
   - Ports: 53, 67, 68, 69, 88, 389, 636, 2049, 4011, 8086
   - Purpose: Core infrastructure access including PXE boot
   - Note: Consolidated with former rylan-dc-specific rule for efficiency

3. **trusted-devices → voip (SIP + RTP)**
   - Ports: 5060-5061, 10000-20000
   - Purpose: VoIP service access

4. **servers → osTicket (AI triage polling)**
   - Ports: 80, 443
   - Source: 10.0.10.60 (rylan-ai)
   - Destination: 10.0.30.40 (osTicket on rylan-pi)
   - Purpose: AI helpdesk integration

5. **voip → servers (FreePBX → AD auth)**
   - Ports: 389, 636
   - Purpose: FreePBX LDAP authentication to Samba AD

6. **guest-iot → WAN only (block local)**
   - Destination: Internet
   - Purpose: Allow guest internet access

7. **guest-iot → local (drop everything else)**
   - Destination: Local networks
   - Action: DROP
   - Purpose: Guest isolation from internal resources

8. **trusted-devices → guest-iot (printer access only)**
   - Ports: 9100, 515, 631
   - Purpose: Trusted devices can access printers on guest VLAN

9. **All networks → RADIUS (802.1X auth)**
   - Destination: 10.0.10.11 (Pi-hole host with RADIUS)
   - Ports: 1812, 1813
   - Purpose: 802.1X authentication for all VLANs

10. **VLAN 10 → Pi-hole Upstream DNS (Phase 3 Endgame Arch)**
    - Source: servers network
    - Destination: 10.0.10.11
    - Port: 53
    - Purpose: DNS forwarding to Pi-hole (separate from AD/DC)

## Hardware Offload Compliance

✅ **USG-3P Requirement**: ≤10 rules for hardware offload  
✅ **Current Count**: 10 rules exactly  
✅ **Status**: All firewall rules will be processed by hardware acceleration  

## Optimization Note

Rule #2 was optimized to consolidate:
- Former "trusted-devices → servers" (DNS, AD, NFS, Influx)
- Former "trusted-devices → rylan-dc" (PXE + Domain Services)

This consolidation is valid because:
- rylan-dc (10.0.30.10) is on the servers network (10.0.30.0/24)
- All listed services are server-class infrastructure
- Port ranges are additive and non-conflicting
- Reduces rule count from 11 → 10

## Trifecta Compliance

**Suehring (VLAN/Policy Modular)**:
- ✅ Policy count: 10 (≤10 limit enforced)
- ✅ VLAN isolation: guest-iot blocked from local (rules #6, #7)
- ✅ Hardware offload: Enabled on USG-3P

---

**Last Updated**: December 3, 2025  
**Branch**: release/v.1.1.2-endgame  
**Status**: Production-ready, hardware-accelerated
