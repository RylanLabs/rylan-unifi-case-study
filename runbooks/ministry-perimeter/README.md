# Ministry of Perimeter — Suehring Policy Enforcement (Phase 3)

**Status**: Production-ready  
**Estimated Deployment Time**: <45 seconds (atomic one-shot)  
**Depends On**: Phase 1 (Secrets) + Phase 2 (Whispers) ✓  
**Rollback**: Restore policy table and VLAN configs from backups

## Overview

The **Ministry of Perimeter** enforces the **Suehring network segmentation** foundation:
- **Policy table** (≤10 rules) — hardware offload safe for USG-3P
- **VLAN isolation** — guest/IoT blocked from internal (VLAN 90 → WAN only)
- **Rogue DHCP detection** — webhook to osTicket AI triage
- **QoS/DSCP** — VoIP priority (EF/DSCP 46)

This phase seals the network perimeter and ensures no unauthorized traffic flows between segments.

---

## Quick Deploy (Copy-Paste)

```bash
# 1. Prerequisites: Phase 1 + 2 complete
sudo systemctl status samba-ad-dc  # Should be active
sudo systemctl status nftables     # Should be active

# 2. Run Phase 3 (Perimeter/Policy) — Atomic One-Shot
sudo bash ./runbooks/ministry-perimeter/rylan-suehring-eternal-one-shot.sh
```

**Expected output:**
```
[PERIMETER] Phase 3.1: Policy table deployment (≤10 rules)
✓ Policy table validated: 10 rules ≤10 (hardware offload safe)
✓ Rogue DHCP detection script deployed
✓ VLAN isolation test matrix created
[✓ SUCCESS] Phase 3 COMPLETE: Ministry of Perimeter policies deployed
```

---

## The 10 Sacred Rules (Suehring Law)

| # | Name | Source VLAN | Dest VLAN | Action | Purpose |
|---|------|-------------|----------|--------|---------|
| 1 | Guest → Internet | 90 | WAN | ACCEPT | IoT/Guest internet-only access |
| 2 | Guest → Local (BLOCK) | 90 | 10,30,40 | DROP | Isolation: guest blocked from internal |
| 3 | Servers NFS | 10 | 10 | ACCEPT | NFS backup (port 2049) |
| 4 | DNS/DHCP | 10,30,40,90 | 1 | ACCEPT | UDP 53/67/68 (management VLAN) |
| 5 | VoIP RTP | 40 | 10 | ACCEPT | UDP 10000-20000, EF/DSCP 46 |
| 6 | Management SSH | 1,10,30 | 10 | ACCEPT | TCP 22 (ops access) |
| 7 | Trusted Services | 30 | 10,40 | ACCEPT | TCP 443/3000/5000 (HTTP/API) |
| 8 | VoIP SIP | 40 | 10 | ACCEPT | TCP 5060/5061 (signaling) |
| 9 | DHCP Monitoring | 10,30,40,90 | 1 | ACCEPT | UDP 67 (rogue detection, logged) |
| 10 | DEFAULT DROP | any | any | DROP | Implicit deny (hardware offload boundary) |

**IMMUTABLE**: Rule count MUST be ≤10 for USG-3P hardware offload.

---

## VLAN Segmentation

| VLAN | Name | IPs | Purpose |
|------|------|-----|---------|
| 1 | Management | 10.0.1.0/24 | USG, UniFi controller, monitoring |
| 10 | Servers | 10.0.10.0/24 | Samba AD/DC, NFS, FreeRADIUS, AI |
| 30 | Trusted | 10.0.30.0/24 | Raspberry Pi (osTicket), trusted clients |
| 40 | VoIP | 10.0.40.0/24 | Grandstream phones (macvlan, DSCP 46) |
| 90 | Guest/IoT | 10.0.90.0/24 | Guests, smart devices (internet-only) |

---

## Policy Table Validation

After deployment, verify:

```bash
# Check policy table JSON
python3 -m json.tool ./02-declarative-config/policy-table-v5.json

# Count rules
python3 -c "import json; print(len(json.load(open('./02-declarative-config/policy-table-v5.json'))['firewall_rules']))"

# Verify ≤10 rules (should print 10)
```

---

## Rogue DHCP Detection

The detection webhook monitors unauthorized DHCP servers:

```bash
# View detection script
cat /usr/local/bin/detect-rogue-dhcp.sh

# Test detection (manual DHCP offer simulation)
# On detection: POST to osTicket webhook
# Alert subject: "🚨 Rogue DHCP Server Detected"
# Priority: urgent
# Department: Network Security
```

Integration with osTicket:

- **Webhook URL**: `${OSTICKET_WEBHOOK_URL}` (set in `.env`)
- **Alert type**: security_alert
- **Triage**: AI helpdesk routes to Network Security team
- **Response time**: <5 min (osTicket SLA)

---

## QoS / DSCP Configuration

VoIP traffic (VLAN 40) is marked with **EF (Expedited Forwarding, DSCP 46)**:

```bash
# Verify DSCP on USG
show traffic-policy priority-queue

# Expected output: Queue 0 (VoIP) = DSCP 46 (EF)
```

---

## Validation Checklist

After deployment, verify:

- [ ] **Policy table rule count**: `10 ≤ 10` ✓
- [ ] **Policy table JSON valid**: `python3 -m json.tool` (no errors)
- [ ] **Rogue DHCP script deployed**: `ls -la /usr/local/bin/detect-rogue-dhcp.sh`
- [ ] **VLANs exist**: `cat /proc/net/vlan/config` (should list VLANs 1,10,30,40,90)
- [ ] **DSCP marking**: `show traffic-policy priority-queue` (EF on VoIP queue)
- [ ] **Audit logging**: `systemctl status auditd` (active)

---

## Troubleshooting

### Policy table exceeds 10 rules
**Cause**: New rule added without consolidation  
**Fix**: Consolidate rules before adding new ones

```bash
# Example: Merge similar rules
# OLD: Rule 6a, 6b, 6c (three separate SSH rules)
# NEW: Rule 6 (combined SSH from 1,10,30)
```

### Rogue DHCP webhook not triggering
**Cause**: osTicket webhook URL not set or tcpdump not running  
**Fix**:

```bash
# Verify osTicket URL in .env
grep OSTICKET_WEBHOOK_URL .env

# Test webhook manually
curl -X POST "${OSTICKET_WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -d '{"subject":"Test","priority":"urgent"}'
```

### VLAN traffic blocked unexpectedly
**Cause**: Policy rule priority conflict or nftables rule overriding policy table  
**Fix**:

```bash
# Check nftables rules (may override)
sudo nft list ruleset

# Verify UniFi policy table applied
show firewall group
```

### Guest traffic leaking to internal VLAN
**Cause**: Rule 2 (Guest → Local) misconfigured  
**Fix**: Verify rule 2 is DROP for destination VLANs 10,30,40

```bash
# On USG: show firewall name GUEST_TO_LOCAL
```

---

## Rollback Procedure

If Phase 3 needs to be reverted:

```bash
# 1. Restore previous policy table
cp ./02-declarative-config/policy-table-v4.json ./02-declarative-config/policy-table-v5.json

# 2. Remove rogue DHCP detection
sudo rm /usr/local/bin/detect-rogue-dhcp.sh

# 3. Revert VLAN configuration
# (Manual on UniFi or via playbook)
```

---

## What Happens Next

Once Phase 3 (Perimeter) is complete, run **Final Validation**:

```bash
sudo bash ./scripts/ignite.sh
# or directly:
sudo bash ./validate-eternal.sh
```

This verifies:
- ✓ All 3 ministries active
- ✓ Eternal fortress eternal (15-min RTO)
- ✓ 100% green checks

---

## Key Files

| File | Purpose |
|------|---------|
| `rylan-suehring-eternal-one-shot.sh` | Phase 3 orchestrator (atomic, <45s) |
| `README.md` | This file |
| `../../02-declarative-config/policy-table.yaml` | Policy table (10 rules, sacred) |
| `/usr/local/bin/detect-rogue-dhcp.sh` | Rogue DHCP detection webhook |

---

## Security Notes

🔐 **Policy table is immutable** — do not exceed 10 rules.  
🔐 **VLAN isolation is mandatory** — guest ↔ internal must be blocked.  
🔐 **Rogue DHCP alerts** go to osTicket → AI triage → Network Security team.  
🔐 **QoS/DSCP** ensures VoIP quality (EF/46 priority).

---

## Questions?

Run the deployment with verbose logging:

```bash
bash -x ./runbooks/ministry-perimeter/rylan-suehring-eternal-one-shot.sh
```

Check comprehensive status:

```bash
show firewall rule  # UniFi policy table
show vlan
show traffic-policy priority-queue  # DSCP/QoS
```

Review audit logs:

```bash
sudo tail -f /var/log/audit/audit.log | grep firewall
```
