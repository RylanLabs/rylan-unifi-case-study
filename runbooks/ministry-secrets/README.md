# Ministry of Secrets — Carter Eternal Identity (Phase 1)

**Status**: T3-ETERNAL v6 | **Time**: <90s | **Domain**: `rylan.internal`

Provisions Samba AD/DC with LDAPS-only, machine keytabs, zero passwords.

## Prerequisites

```bash
openssl rand -base64 32 > /root/rylan-unifi-case-study/.secrets/samba-admin-pass
chmod 400 /root/rylan-unifi-case-study/.secrets/samba-admin-pass
```

## Deploy

```bash
sudo bash ./runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
```
