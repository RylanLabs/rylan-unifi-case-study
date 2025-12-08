# ADR-015: VLAN Expansion Limits for USG-3P Hardware Offload

**Status:** Accepted
**Date:** 2025-12-04
**Context:** v∞.1.2-iot-ready — Locking VLAN count at 6 to preserve hardware offload

## Context

USG-3P has documented hardware offload limits:
- **Firewall rules**: ≤10 rules for hardware acceleration
- **VLANs**: Ubiquiti docs unclear on hard limit, but >5 VLANs can degrade performance

Current VLAN count (v∞.1.2):
1. VLAN 1: Management (default)
2. VLAN 10: Servers (AD, NFS, Pi-hole)
3. VLAN 30: Trusted devices (workstations, phones)
4. VLAN 40: VoIP (FreePBX, phones)
5. VLAN 90: Guest/IoT (untrusted guest WiFi)
6. VLAN 95: IoT-isolated (Traeger grill)
7. [Removed historical VLAN entry]

**Total: 6 VLANs** (including management)

## Decision

**Lock VLAN count at 6 custom VLANs + 1 management = 7 total.**

Do not add additional VLANs without:
1. Consolidating existing VLANs (e.g., merging guest-iot 90 + iot-isolated 95)
2. Upgrading to UDM-Pro or UXG-Pro
3. Performance testing confirming no offload degradation

## Rationale

### USG-3P Performance Constraints
- **CPU**: Cavium Octeon (500 MHz MIPS64) — limited packet processing without offload
- **Hardware offload**: Enabled for simple routing, basic firewall rules, NAT
- **Offload breaks when**: Complex DPI, >10 firewall rules, excessive VLAN tagging

### Observed Safe Limits (Community + Testing)
- **≤5 VLANs**: Universally safe, no reported offload issues
- **6-8 VLANs**: Generally safe with ≤10 firewall rules
- **>8 VLANs**: Reports of CPU spikes, offload bypass, throughput degradation

### Current Configuration Safety
- **7 VLANs**: Within safe range
- **9 firewall rules**: Below 10-rule threshold (Phase 3 endgame locked)
- **No DPI**: Deep packet inspection disabled (Carter principle: simple, auditable)

## Alternatives Considered

1. **Unlimited VLAN expansion (rejected)**: Risks hardware offload bypass, degrades RTO
2. **Merge guest-iot 90 + iot-isolated 95 (considered)**: Would free 1 VLAN slot but loses guest WiFi separation
3. **Upgrade to UDM-Pro (future)**: When USG-3P reaches EOL or performance degrades

## Consequences

### Positive
- **Preserves hardware offload**: Routing/NAT acceleration maintained
- **Predictable performance**: USG-3P within tested limits
- **Suehring compliant**: Network perimeter remains simple, auditable

### Negative
- **VLAN flexibility limited**: No additional VLANs without consolidation
- **Forces design discipline**: Must justify each VLAN addition (good constraint)

## Monitoring & Validation

Add to `03-validation-ops/orchestrator.sh`:

```bash
# Check USG-3P CPU usage
USG_CPU=$(ssh admin@$USG_IP "top -b -n 1 | grep 'CPU:' | awk '{print \$2}'")
if [ "${USG_CPU%\%}" -gt 80 ]; then
  log_error "USG-3P CPU >80% — possible offload bypass"
fi
```

Target: **CPU <80%** under normal load (RTO validation)

## Implementation

- **v∞.1.2**: Lock at 7 VLANs (current state)
- **v∞.2.x**: Add CPU monitoring to orchestrator.sh
- **v∞.3.x**: Evaluate UDM-Pro if CPU consistently >80%

## References
- Ubiquiti community: [USG-3P VLAN performance thread](https://community.ui.com/questions/USG-3P-VLAN-performance)
- Suehring (2005): "Simplicity enables security"
- Phase 3 endgame: ≤10 firewall rules (hardware offload preserved)
- Trinity: Carter — "Identity as infrastructure" (VLANs = identity boundaries)
