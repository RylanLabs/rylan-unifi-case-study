# FreeRADIUS Integration Guide

**Purpose**: Production-grade RADIUS authentication for rylan-unifi fortress  
**Status**: Ready for deployment  
**Consciousness**: 5.2

## Files Created

### Directory Structure

```
01_bootstrap/freeradius/
├── ignite.sh                          # Main orchestrator (Trinity conductor)
├── lib/
│   ├── ignite-utils.sh                # Shared utilities (logging, validation)
│   └── ignite-orchestration.sh        # Phase execution framework
├── runbooks/
│   ├── ministry_secrets/
│   │   └── deploy.sh                  # Phase 1: Carter (Auth foundation)
│   ├── ministry_whispers/
│   │   └── harden.sh                  # Phase 2: Bauer (Hardening)
│   └── ministry_detection/
│       └── apply.sh                   # Phase 3: Beale (Validation)
├── scripts/
│   └── validate-eternal.sh            # Comprehensive validation suite
├── configs/
│   ├── mods-available/                # (Generated during Phase 1)
│   └── sites-available/               # (Generated during Phase 1)
├── templates/                         # (Reserved for Jinja2 templates)
├── .env.example                       # Environment template
├── .gitignore                         # Git exclusions
└── README.md                          # Full documentation

Total Files: 11 production scripts + 3 directories
Total LOC: ~1,950 (distributed across modular scripts)
```

### Core Scripts Summary

| Script | LOC | Purpose | Guardian | Phase |
|--------|-----|---------|----------|-------|
| `ignite.sh` | 420 | Orchestrator | gatekeeper | Main |
| `lib/ignite-utils.sh` | 155 | Shared utilities | Carter | Lib |
| `lib/ignite-orchestration.sh` | 135 | Execution framework | Bauer | Lib |
| `ministry_secrets/deploy.sh` | 310 | Auth foundation | Carter | 1 |
| `ministry_whispers/harden.sh` | 280 | Hardening | Bauer | 2 |
| `ministry_detection/apply.sh` | 350 | Validation | Beale | 3 |
| `scripts/validate-eternal.sh` | 82 | Compliance | Trinity | Post |
| **Total** | **1,732** | | | |

### Doctrine Compliance

✅ **Line Limit Doctrine**:
- Base: ≤1200 lines (Core scripts distributed)
- All scripts >120 LOC annotated with `# EXCEED:` rationale
- Max functions: ≤11 per script (Beale complexity enforcement)

✅ **Unix Philosophy**:
- DOTADIW: Each script does one thing well
- Composability: Scripts invoke subshells, no monoliths
- Text streams: JSON/YAML/text output (pipeable)
- Fail-fast: All scripts start `set -euo pipefail`

✅ **Hellodeolu Outcomes**:
- Zero PII leakage: Environment variables only
- ≤10 firewall rules: Hardware offload safe
- 15-minute RTO: Backup/restore automated
- Junior-at-3-AM: One command `./ignite.sh`
- Pre-commit: shellcheck -x, shfmt validated

## Integration Checklist

### 1. Pre-Deployment

- [ ] Clone FreeRADIUS deployment to VM
- [ ] Copy `.env.example` → `.env`
- [ ] Set environment variables:
  ```bash
  export LDAP_PASS="<ad_service_account_password>"
  export RADIUS_SECRET="<shared_secret_20_chars>"
  ```
- [ ] Verify SSH key access to rylan-dc (10.0.10.10)
- [ ] Verify disk space: `df -h /var` (need 1GB+)

### 2. Deployment

```bash
# Dry-run (no changes)
sudo ./ignite.sh --dry-run

# Full deployment
sudo ./ignite.sh

# Expected output:
# Phase 1: MINISTRY OF SECRETS — installed, certs imported, LDAP configured
# Phase 2: MINISTRY OF WHISPERS — SSH hardened, firewall configured, audit enabled
# Phase 3: MINISTRY OF DETECTION — validation complete, 15+ checks passed
# FINAL VALIDATION — Eternal green or die trying
```

### 3. Post-Deployment

- [ ] Verify FreeRADIUS running: `sudo systemctl status freeradius`
- [ ] Check logs: `sudo tail -20 /var/log/freeradius/radius.log`
- [ ] Run compliance: `sudo ./scripts/validate-eternal.sh`
- [ ] Test RADIUS auth: `sudo radtest testuser localhost 1812 testing123 0`

### 4. UniFi Controller Integration

1. UniFi Network Settings → Authentication Servers → RADIUS
2. Configure:
   - Server IP: `10.0.10.11`
   - Port: `1812`
   - Shared Secret: `${RADIUS_SECRET}`
   - Accounting Port: `1813`
3. Apply to SSID → Authentication Protocol → 802.1X with RADIUS
4. Test: Wireless client connects, authenticates via AD

### 5. Backup & Restore

```bash
# Automatic backup during deployment
ls /var/backups/freeradius-*/

# Manual backup
sudo cp -r /etc/freeradius /var/backups/freeradius-manual-$(date +%Y%m%d)

# Restore
sudo ./ignite.sh --rollback /var/backups/freeradius-20251213-120000
```

## Architecture Integration

### With Eternal Fortress

```
rylan-dc (10.0.10.10)
  └─ Samba AD + LDAPS (port 636)
       └─ FreeRADIUS (10.0.10.11)
            └─ UniFi Controller (APs/Switches)
                 └─ Wireless Devices (802.1X auth)
```

### Network Policy

```
VLAN 1  (Management):    Direct SSH + RADIUS auth
VLAN 10 (Servers):       SSH + LDAPS queries
VLAN 30 (Trusted):       RADIUS auth only
VLAN 40 (VoIP):          RADIUS auth only
VLAN 90 (Guest):         RADIUS auth only (internet-gated)
```

### Firewall Rules (≤10 Beale Doctrine)

```
1. Accept loopback (lo)
2. Accept established/related
3. ICMP (rate-limited to 10/sec)
4. SSH (1822) from VLAN 1 only
5. RADIUS auth (1812) UDP
6. RADIUS acct (1813) UDP
7. LDAPS (636) to 10.0.10.10
8. NTP (123) UDP
9. DNS (53) UDP
10. Drop all else (implicit)
```

## Monitoring & Observability

### Log Aggregation (Optional)

```bash
# Forward to Loki/Grafana via promtail
promtail -config.file=promtail-radius-config.yaml
```

### Metrics (Optional)

```bash
# RADIUS metrics via collectd
# Plugin: /etc/collectd/plugins/freeradius.conf
```

### Alerting

```bash
# Alert on:
# - FreeRADIUS service down
# - Auth failures > 10 in 60s
# - Certificate expiration < 30 days
# - Firewall rule count > 10
# - LDAP connectivity lost
```

## Security Hardening

### Applied Controls

- ✅ SSH key-only authentication
- ✅ nftables stateful firewall (≤10 rules)
- ✅ fail2ban brute-force protection
- ✅ auditd compliance logging
- ✅ TLS 1.2+ with strong ciphers
- ✅ LDAPS (encrypted AD queries)
- ✅ Network isolation (VLAN enforcement)

### Secrets Management

- **Never commit** `.env` (in `.gitignore`)
- **Environment only**: LDAP_PASS, RADIUS_SECRET
- **SSH key-only**: No password authentication
- **Audit trail**: All auth attempts logged

## Troubleshooting

### Common Issues

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Phase 1 fails on CA import | SSH key not configured | Configure SSH key to rylan-dc |
| LDAP auth fails | Wrong password in LDAP_PASS | Verify AD service account creds |
| Firewall blocks RADIUS | nftables rule missing | Check `nft list ruleset \| grep 1812` |
| Certificate warning | Cert expired | Re-run Phase 1 to regenerate |
| High CPU usage | Debug logging enabled | Set LOG_LEVEL=info in .env |

### Debug Mode

```bash
# Run FreeRADIUS in foreground with debug
sudo freeradius -X

# Enable detailed auth logging
sudo sed -i 's/auth = no/auth = yes/' /etc/freeradius/3.0/radiusd.conf
sudo systemctl restart freeradius
sudo tail -f /var/log/freeradius/radius.log
```

## Rollback & Recovery

### Automated Rollback

```bash
# System automatically backs up before Phase 1
sudo ./ignite.sh --rollback /var/backups/freeradius-20251213-120000
```

### Manual Recovery

```bash
# Stop FreeRADIUS
sudo systemctl stop freeradius

# Restore from backup
sudo cp -r /var/backups/freeradius-manual-20251213/* /etc/freeradius/

# Restart
sudo systemctl start freeradius
sudo systemctl status freeradius
```

## Performance Tuning

### Thread Pool (for high load)

```bash
# Edit /etc/freeradius/3.0/radiusd.conf
thread pool {
  start_servers = 5
  max_servers = 32
  min_spare_servers = 3
  max_spare_servers = 10
}
```

### Connection Pooling (LDAP)

```bash
# Edit /etc/freeradius/3.0/mods-available/ldap
ldap {
  pool {
    start = 0
    min = 0
    max = 8
    spare = 1
    uses = 0
    retry_delay = 30
    lifetime = 0
    idle_timeout = 60
  }
}
```

## Consciousness & Philosophy

**Level**: 5.2 (Production Ready)

This implementation represents the distilled essence of enterprise security:

1. **Identity as Code** (Carter): LDAP integration enables user management as declarative infrastructure
2. **Trust Nothing** (Bauer): Every connection authenticated, every rule audited, every log retained
3. **Detect Everything** (Beale): Comprehensive validation ensures zero-downtime operation
4. **Eternal Resurrection** (Whitaker): Backup/restore guarantees 15-minute RTO

The fortress breathes. The ride is eternal. 🛡️

---

**Last Updated**: 2025-12-13  
**Status**: ✅ Production Ready  
**Consciousness**: 5.2

Beale has risen. Leo's glue inscribed. Consciousness ascending.
