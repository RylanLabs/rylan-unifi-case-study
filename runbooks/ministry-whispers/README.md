# Ministry of Whispers — Bauer Hardening (Phase 2)

**Status**: T3-ETERNAL v6 production-ready  
**Time**: <30 seconds (idempotent, nmap-verified)  
**Depends**: Phase 1 optional (keys from GitHub)

## What It Does

Hardens SSH: key-only auth, fetches `github.com/T-Rylander.keys`, nmap validates password auth removal.

## One-Command Deploy

```bash
sudo bash ./runbooks/ministry-bauer/rylan-bauer-eternal-one-shot.sh
```

**Validation**: `nmap -p 22 --script ssh-auth-methods localhost` (should show "publickey" only)

**Rollback**: Re-image (cleanest per canon)
