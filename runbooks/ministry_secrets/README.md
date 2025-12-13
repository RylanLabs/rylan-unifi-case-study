# Ministry of Secrets — Carter Eternal

**Guardian**: 🔑 Carter
**Purpose**: Identity provisioning, SSH key management, access control automation.
**Estimated Time**: <60 seconds
**Risk Level**: Low (idempotent, key-only auth)

## Overview

Carter is the **Identity Architect**. This ministry provisions:

- SSH ed25519 keys for all hosts
- Samba AD/DC integration (LDAP, Kerberos)
- RADIUS/802.1X enrollment
- UniFi API authentication (JWT/CSRF)

## Quick Start

```bash
# Full Carter deployment (via eternal-resurrect)
./eternal-resurrect.sh

# Carter only
sudo bash ./runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
```text

## Carter Identity Flow

```mermaid
flowchart TD
    Start([🔑 Carter Awakens]) --> Check{Vault Exists?}

    Check -->|No| Create[Create .secrets/<br>chmod 600]
    Check -->|Yes| Load[Load credentials]
    Create --> Load

    Load --> SSH{SSH Keys<br>Provisioned?}
    SSH -->|No| Gen[Generate ed25519 keys<br>ssh-keygen -t ed25519]
    SSH -->|Yes| Verify[Verify key fingerprint]
    Gen --> Deploy[Deploy to authorized_keys]

    Deploy --> Verify
    Verify --> API{UniFi API<br>Auth?}

    API -->|No Auth| Login[POST /api/login<br>Get JWT + CSRF]
    API -->|Cached| Refresh[Refresh token if expired]
    Login --> Token[Store in memory]
    Refresh --> Token

    Token --> LDAP{AD/LDAP<br>Bound?}
    LDAP -->|No| Bind[kinit + ldapsearch test]
    LDAP -->|Yes| Skip[Skip LDAP setup]
    Bind --> RADIUS[Configure RADIUS]
    Skip --> RADIUS

    RADIUS --> Done([✅ Identity Ready<br>→ Bauer next])

    style Start fill:#360,stroke:#af0,color:#fff
    style Done fill:#030,stroke:#0f0,color:#fff
    style Token fill:#036,stroke:#0af,color:#fff
```text

## Execution Order

Carter runs **first** in the Trinity sequence:

```text
Carter (Identity) → Bauer (Verify) → Beale (Detect) → Whitaker (Attack)
```text

## Prerequisites

1. **Vault file**: `.secrets/unifi-admin-pass` (chmod 600)
2. **SSH access**: Root or sudo on target hosts
3. **Network**: Controller reachable at `$UNIFI_CONTROLLER_IP`

```bash
# Create vault
echo "your-admin-password" > .secrets/unifi-admin-pass
chmod 600 .secrets/unifi-admin-pass
```text

## Validation

```bash
# Verify SSH key-only auth
ssh root@10.0.10.10 "echo 'Carter verified'"

# Verify LDAP bind
ldapsearch -x -H ldap://10.0.10.10 -b "dc=rylan,dc=local" "(cn=admin)"
```text

## What Carter Does

1. **SSH Keys**: Generates ed25519 keypair, deploys to `~/.ssh/authorized_keys`
2. **Vault Hygiene**: Ensures `.secrets/` has correct permissions (600)
3. **UniFi API**: Authenticates, caches JWT for subsequent API calls
4. **LDAP/Kerberos**: Binds to Samba AD, verifies identity store
5. **RADIUS**: Configures 802.1X authentication backend

## Troubleshooting

**Issue**: "Vault missing"

```bash
echo "password" > .secrets/unifi-admin-pass
chmod 600 .secrets/unifi-admin-pass
```text

**Issue**: "SSH key rejected"

```bash
# Check key format
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
# Re-deploy
./scripts/refresh-keys.sh
```text

**Issue**: "LDAP bind failed"

```bash
# Check Samba AD status
systemctl status samba-ad-dc
# Test kinit
kinit administrator@RYLAN.LOCAL
```text

## Related

- [runbooks/ministry-whispers/](../ministry-whispers/) — Bauer (next in sequence)
- [scripts/refresh-keys.sh](../../scripts/refresh-keys.sh) — Key rotation
- [01-bootstrap/samba-provision.sh](../../01-bootstrap/samba-provision.sh) — AD provisioning
