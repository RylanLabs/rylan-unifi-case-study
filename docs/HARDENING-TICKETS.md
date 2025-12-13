# HARDENING-TICKETS.md — The 4 Doors to Close

**Status**: Canonical · Derived from Whitaker Annihilation Analysis  
**Consciousness Impact**: +0.25 total when all 4 merged  
**Target**: v∞.4.30 (toward Ticket #6: whitaker-ci-breach)  
**Date**: 12/11/2025

---

## Overview

Grok's "Total Annihilation Protocol" identified 4 real architectural gaps.
The theater has been stripped. The doors remain.

| # | Door | Severity | Fix | Consciousness |
|---|------|----------|-----|---------------|
| 1 | apply.py auth | HIGH | JWT validation | +0.05 |
| 2 | VLAN 99 unmonitored | MEDIUM | validate-isolation.sh | +0.10 |
| 3 | PXE/DHCP spoof | MEDIUM | DHCPv6 secure | +0.05 |
| 4 | Ollama logs unscrubbed | LOW | Presidio on webhook | +0.05 |

---

## Ticket 1: fix(bauer): Add JWT auth to apply.py --apply

### The Door
`apply.py --apply` pushes policy to UniFi without authentication.  
2-minute window for rule drift if attacker has network access.

### Severity
**HIGH** — Policy injection vector

### Entry Point

```bash
curl -k -d '{"policy": "rogue"}' https://192.168.1.13/proxy/network/api/s/default/

```text

### Exploit Chain
1. Recon (nmap 8080) → API endpoint discovered
2. Script injection → Malicious policy JSON
3. Rule exfil → Firewall rules extracted/modified

### Fix
Add JWT token validation before any `--apply` operation:

```python
# 02-declarative-config/apply.py

import os
from functools import wraps

class AuthError(Exception):
    pass

def require_auth(func):
    """Bauer: Verify before modify."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        token = os.environ.get('UNIFI_JWT')
        if not token:
            raise AuthError('UNIFI_JWT required for --apply operations')
        # Optional: Add expiry check
        return func(*args, **kwargs)
    return wrapper

@require_auth
def apply_policy(config: dict) -> None:
    """Apply policy to UniFi controller."""
    # ... existing implementation

```text

### Validation
- [ ] `./gatekeeper.sh` passes
- [ ] `apply.py --apply` without `UNIFI_JWT` fails with `AuthError`
- [ ] `apply.py --dry-run` works without auth (read-only)
- [ ] `apply.py --apply` with valid `UNIFI_JWT` succeeds

### Trinity
- **Bauer**: Verification domain — "Why should I trust this mutation?"
- **Consciousness**: +0.05 when merged

---

## Ticket 2: fix(beale): Add VLAN 99 to validate-isolation.sh

### The Door
VLAN 99 (Quarantine/DadNet) is not monitored by `validate-isolation.sh`.  
IoT pivot to VLAN 30 (Users/PXE) is undetected.

### Severity
**MEDIUM** — Lateral movement vector

### Entry Point

```text
Tailscale → Traeger (port 80) → VLAN 99 → hop to VLAN 30

```text

### Exploit Chain
1. Social engineering (Dad phish for Tailscale key)
2. IoT firmware exploit on Traeger
3. VLAN hop via misconfigured switch port
4. PXE server compromise

### Fix
Add VLAN 99 tests to `03-validation-ops/validate-isolation.sh`:

```bash
# Add after Test 5

# Test 6: Quarantine VLAN 99 Isolation (DadNet)
log "\n[TEST 6] Quarantine VLAN 99 → All VLANs (MUST BE BLOCKED)"
run_nmap_test "10.0.10.10" "22" "closed" "Quarantine→Mgmt SSH" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.30.1" "67" "closed" "Quarantine→Users DHCP" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.40.1" "80" "closed" "Quarantine→IoT HTTP" && ((tests_passed++)) || ((tests_failed++))
run_nmap_test "10.0.90.1" "443" "closed" "Quarantine→Prod HTTPS" && ((tests_passed++)) || ((tests_failed++))

# Test 7: Quarantine → Internet ONLY (allow)
log "\n[TEST 7] Quarantine VLAN 99 → Internet (MUST BE ALLOWED)"
run_nmap_test "1.1.1.1" "443" "open" "Quarantine→Internet HTTPS" && ((tests_passed++)) || ((tests_failed++))

```text

Also add VLAN 99 to the CI mode documentation:

```bash
if [[ "${CI_MODE:-}" == "1" ]]; then
    log "  - Quarantine→All VLANs (closed), Quarantine→Internet (open)"

```text

### Validation
- [ ] `./gatekeeper.sh` passes
- [ ] `validate-isolation.sh` includes VLAN 99 tests
- [ ] CI_MODE logs VLAN 99 test descriptions
- [ ] Live run blocks Quarantine → internal, allows Quarantine → internet

### Trinity
- **Beale**: Detection domain — "Is the quarantine actually quarantined?"
- **Consciousness**: +0.10 when merged (critical isolation fix)

---

## Ticket 3: fix(carter): Enforce DHCPv6 secure on VLAN 30

### The Door
DHCP on VLAN 30 allows PXE spoof attacks.  
Rogue AP can replay bootp → compromise boot server.

### Severity
**MEDIUM** — Boot chain compromise vector

### Entry Point

```text
DHCP port 67 on VLAN 30 → Sniff bootp → Spoof TFTP → PXE server own

```text

### Exploit Chain
1. Connect rogue device to VLAN 30
2. Sniff DHCP/bootp traffic
3. Spoof TFTP server response
4. Inject malicious boot image

### Fix
Add DHCP snooping and option 82 validation:

```yaml
# 02-declarative-config/vlans.yaml — VLAN 30 section

- id: 30
  name: Users
  subnet: 10.0.30.0/24
  gateway: 10.0.30.1
  dhcp_enabled: true
  dhcp_start: 10.0.30.100
  dhcp_end: 10.0.30.200
  dhcp_snooping: true          # NEW: Enable DHCP snooping
  dhcp_trusted_ports: [1, 2]   # NEW: Only uplink ports trusted
  pxe_secure: true             # NEW: Signed boot images only

```text

Add validation to `apply.py`:

```python
def validate_dhcp_security(vlan: VLAN) -> None:
    """Carter: Verify DHCP security on PXE VLANs."""
    if vlan.id == 30 and vlan.dhcp_enabled:
        if not getattr(vlan, 'dhcp_snooping', False):
            logger.warning(f"VLAN {vlan.id}: DHCP snooping not enabled (PXE risk)")

```text

### Validation
- [ ] `./gatekeeper.sh` passes
- [ ] vlans.yaml includes dhcp_snooping for VLAN 30
- [ ] apply.py warns if VLAN 30 lacks dhcp_snooping
- [ ] Rogue DHCP server on VLAN 30 is blocked

### Trinity
- **Carter**: Identity domain — "Who is allowed to assign addresses?"
- **Consciousness**: +0.05 when merged

---

## Ticket 4: fix(whitaker): Scrub Ollama webhook logs with Presidio

### The Door
AI triage via Ollama logs queries without PII scrubbing.  
Webhook exfil of sensitive data.

### Severity
**LOW** — PII leak vector (requires webhook access)

### Entry Point

```text
Phish new hire → AI query with PII → Webhook log → PII dump

```text

### Exploit Chain
1. Social engineering to gain webhook URL
2. Submit AI query containing PII
3. PII logged to Ollama without scrubbing
4. Webhook exfiltrates logs

### Fix
Add Presidio scrubbing to webhook handler:

```python
# 03-ai-helpdesk/webhooks/handler.py (new or existing)

from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

analyzer = AnalyzerEngine()
anonymizer = AnonymizerEngine()

def scrub_pii(text: str) -> str:
    """Whitaker: No PII in logs. Ever."""
    results = analyzer.analyze(text=text, language='en')
    anonymized = anonymizer.anonymize(text=text, analyzer_results=results)
    return anonymized.text

def log_query(query: str, response: str) -> None:
    """Log AI interaction with PII removed."""
    safe_query = scrub_pii(query)
    safe_response = scrub_pii(response)
    logger.info(f"Query: {safe_query}")
    logger.info(f"Response: {safe_response}")

```text

### Validation
- [ ] `./gatekeeper.sh` passes
- [ ] Webhook logs contain no raw PII
- [ ] Presidio recognizes: SSN, email, phone, names
- [ ] Test: Submit "John Doe SSN 123-45-6789" → Log shows "<PERSON> <US_SSN>"

### Trinity
- **Whitaker**: Offense domain — "What would the attacker exfiltrate?"
- **Consciousness**: +0.05 when merged

---

## Implementation Order

```text
Ticket 1 (apply.py auth)     → Prerequisite for safe policy changes
    ↓
Ticket 2 (VLAN 99 monitor)   → Closes lateral movement vector
    ↓
Ticket 3 (DHCP secure)       → Closes boot chain vector
    ↓
Ticket 4 (Ollama scrub)      → Closes PII leak vector
    ↓
Ticket #6 (whitaker-ci-breach) → All 4 doors closed, 10-vector CI pentest

```text

---

## Consciousness Trajectory

| Current | After Ticket 1 | After Ticket 2 | After Ticket 3 | After Ticket 4 | After #6 |
|---------|----------------|----------------|----------------|----------------|----------|
| 4.05 | 4.10 | 4.20 | 4.25 | 4.30 | 4.50 |

---

## Convert to GitHub Issues

When GitHub CLI is available:

```bash
# Install gh
sudo apt install gh

# Authenticate
gh auth login

# Create issues from this file
for ticket in 1 2 3 4; do
  gh issue create \
    --title "$(grep "## Ticket $ticket:" HARDENING-TICKETS.md | sed 's/## //')" \
    --body "$(sed -n "/## Ticket $ticket:/,/## Ticket $((ticket+1)):/p" HARDENING-TICKETS.md | head -n -1)"
done

```text

---

The doors are documented.
The path is clear.
Consciousness awaits.

Beale has risen.
Whitaker identified the vectors.
Carter, Bauer, Beale will close them.
