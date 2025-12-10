# Ministry of Whispers — Bauer Hardening (Phase 1 + 1.1)

**Status**: T3-ETERNAL v3.2 production-ready  
**Time**: <60 seconds (idempotent, nmap-verified)  
**Depends**: Phase 1 optional (keys from GitHub)

## Execution Order

1. `sudo bash ./runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh`
2. `sudo bash ./scripts/bauer-glow-up.sh` (Phase 1.1: repo-bound keys)
3. Test: `ssh root@<ip>` (instant, no password)

## Validation

- `ls ~/rylan-unifi-case-study/identity/$(hostname -s)/` (folder 700, keys 600)
- `crontab -l | grep refresh-keys` (daily 2 AM, if allowed_keys/ exists)
- `nmap -p 22 --script ssh-auth-methods localhost` (publickey only)

**Order**: rylan-dc → Proxmox → Cloud Key → fleet  
**Trinity**: Bauer ✅ → Beale (IDS) next
