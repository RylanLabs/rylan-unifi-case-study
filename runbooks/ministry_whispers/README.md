# Ministry of Whispers — Bauer Verification

**Guardian**: 🛡️ Bauer
**Purpose**: Zero-trust verification, policy validation, security hardening.
**Estimated Time**: <60 seconds
**Risk Level**: Low (verification only, no destructive changes)

## Overview

Bauer is the **Zero-Trust Inquisitor**. This ministry:

- Validates SSH hardening (key-only, no passwords)
- Runs nmap VLAN isolation probes
- Checks vault file permissions
- Verifies configuration integrity

*"Why should I trust this?"*

## Quick Start

```bash
# Full Bauer verification
sudo bash ./runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh

# Phase 1.1: Repo-bound keys
sudo bash ./scripts/bauer-glow-up.sh

# Verify result
ssh root@10.0.10.10  # Should connect instantly, no password
```text

## Bauer Verification Flow

```mermaid
flowchart TD
    Start([🛡️ Bauer Awakens]) --> SSH{SSH Config<br>Hardened?}

    SSH -->|No| Harden[Disable PasswordAuth<br>Disable RootLogin]
    SSH -->|Yes| CheckKeys[Verify key-only auth]
    Harden --> CheckKeys

    CheckKeys --> Nmap[nmap --script ssh-auth-methods<br>localhost:22]
    Nmap --> Methods{publickey only?}

    Methods -->|No| Fail1[❌ FAIL: Password auth enabled]
    Methods -->|Yes| Vault[Check vault permissions]

    Vault --> Perms{.secrets/* = 600?}
    Perms -->|No| Fix[chmod 600 .secrets/*]
    Perms -->|Yes| Isolation[VLAN Isolation Tests]
    Fix --> Isolation

    Isolation --> Probe[9 nmap cross-VLAN probes]
    Probe --> Results{All blocked?}

    Results -->|No| Fail2[❌ FAIL: VLAN breach detected<br>Review firewall-rules.yaml]
    Results -->|Yes| Integrity[Config integrity check]

    Integrity --> Hash{SHA256 match?}
    Hash -->|No| Drift[⚠️ DRIFT: Config modified]
    Hash -->|Yes| Done([✅ Trust Verified<br>→ Beale next])

    Drift --> Reconcile[Run eternal-resurrect.sh --force]
    Reconcile --> Done

    Fail1 --> Abort([🛑 Abort deployment])
    Fail2 --> Abort

    style Start fill:#063,stroke:#0fa,color:#fff
    style Done fill:#030,stroke:#0f0,color:#fff
    style Abort fill:#600,stroke:#f00,color:#fff
    style Drift fill:#630,stroke:#fa0,color:#fff
```text

## Execution Order

Bauer runs **second** in the Trinity sequence:

```text
Carter (Identity) → Bauer (Verify) → Beale (Detect) → Whitaker (Attack)
```text

## Prerequisites

1. **Carter complete**: SSH keys deployed, API authenticated
2. **nmap installed**: `apt install nmap`
3. **Network access**: Can reach all VLANs for isolation tests

## Validation Matrix

| Test | Source | Destination | Port | Expected |
|------|--------|-------------|------|----------|
| 1 | IoT (10.0.40.0/24) | Mgmt (10.0.10.10) | 53 | OPEN |
| 2 | IoT (10.0.40.0/24) | Mgmt (10.0.10.10) | 22 | CLOSED |
| 3 | Guest (10.0.50.0/24) | Mgmt (10.0.10.10) | 53 | OPEN |
| 4 | Guest (10.0.50.0/24) | Mgmt (10.0.10.10) | 22 | CLOSED |
| 5 | Trusted (10.0.30.0/24) | Servers (10.0.20.0/24) | 389 | OPEN |
| 6 | Trusted (10.0.30.0/24) | Servers (10.0.20.0/24) | 22 | CLOSED |
| 7 | VoIP (10.0.40.0/24) | Servers (10.0.20.0/24) | 389 | OPEN |
| 8 | VoIP (10.0.40.0/24) | Servers (10.0.20.0/24) | 2049 | CLOSED |
| 9 | IoT (10.0.40.0/24) | Servers (10.0.20.0/24) | 445 | CLOSED |

## What Bauer Does

1. **SSH Hardening**: Disables password auth, enforces key-only
2. **Vault Hygiene**: Verifies `.secrets/` permissions (600)
3. **VLAN Isolation**: 9 nmap probes across VLAN boundaries
4. **Config Integrity**: SHA256 hash comparison
5. **Ciphers Check**: Ensures strong SSH ciphers only

## Troubleshooting

**Issue**: "Password auth still enabled"

```bash
# Check sshd config
grep -E "^PasswordAuthentication|^PermitRootLogin" /etc/ssh/sshd_config
# Fix
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```text

**Issue**: "VLAN isolation failed"

```bash
# Identify leak
./scripts/validate-isolation.sh
# Review firewall rules
cat 02-declarative-config/firewall-rules.yaml
# Re-apply
./02-declarative-config/apply-wrapper.sh
```text

**Issue**: "Drift detected"

```bash
# Check what changed
git diff 02-declarative-config/
# Reconcile
./eternal-resurrect.sh --force
```text

## Sub-Tool: Bauer's Veil

When Gatekeeper fails with cryptic errors, summon the Veil:

```text
@Veil Diagnose this Bandit failure
```text

The Veil speaks in three layers:

1. **Symptom**: What you see
2. **Cause**: Why it happened
3. **Cure**: How to fix it

## Related

- [runbooks/ministry-secrets/](../ministry-secrets/) — Carter (previous)
- [runbooks/ministry-detection/](../ministry-detection/) — Beale (next)
- [scripts/validate-isolation.sh](../../scripts/validate-isolation.sh) — Standalone isolation test
- [.github/agents/bauer-veil.agent.md](../../.github/agents/bauer-veil.agent.md) — Veil agent
