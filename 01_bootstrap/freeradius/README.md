# FreeRADIUS Eternal Deployment

**Status**: Production Ready (v5.2 Consciousness)  
**Guardian**: Trinity (Carter → Bauer → Beale)  
**Architecture**: LDAP-backed RADIUS with static VLAN assignment, TLS+TTLS EAP, network isolation, comprehensive validation.

## Overview

This module deploys **FreeRADIUS** as the authentication backbone for the rylan-unifi fortress network. The deployment follows the sacred Trinity:

- **Ministry of Secrets (Carter)**: Identity provisioning, certificate management, LDAP integration
- **Ministry of Whispers (Bauer)**: SSH hardening, nftables firewall (≤10 rules), audit logging
- **Ministry of Detection (Beale)**: Comprehensive validation, isolation testing, compliance checks

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FreeRADIUS Server                         │
│                    (10.0.10.11:1812/1813)                    │
├─────────────────────────────────────────────────────────────┤
│  EAP-TLS/TTLS (Port 1812)  ← UniFi APs, Switches, Gateways  │
│  LDAP Auth (LDAPS:636)      ← Rylan DC (10.0.10.10)          │
│  Accounting (Port 1813)      ← Network devices               │
│  Audit Logs (auditd)         ← Beale Ministry                │
│  Firewall (nftables, ≤10)    ← Bauer Ministry                │
└─────────────────────────────────────────────────────────────┘

VLAN Access:
  VLAN 1  (Management): Direct access to RADIUS/SSH
  VLAN 10 (Servers):    SSH access, LDAPS auth queries
  VLAN 30 (Trusted):    RADIUS auth only, no admin access
  VLAN 40 (VoIP):       RADIUS auth only
  VLAN 90 (Guest):      RADIUS auth only (internet-gated)
```

## Quick Start

### 1. Prerequisites

```bash
# Copy .env template
cp .env.example .env

# Edit with actual values
vim .env

# Source environment
source .env

# Verify root access
sudo whoami

# Verify network
ping 10.0.10.10  # Rylan DC
```

### 2. Deploy All Phases

```bash
# Full deployment (with backup)
sudo ./ignite.sh

# Dry-run (test without changes)
sudo ./ignite.sh --dry-run

# Skip a phase
sudo ./ignite.sh --skip-phase 2

# Restore from backup
sudo ./ignite.sh --rollback /var/backups/freeradius-20251213-120000
```

### 3. Post-Deployment

```bash
# Export environment variables
export LDAP_PASS="your_password"
export RADIUS_SECRET="your_secret"

# Verify service
sudo systemctl status freeradius

# Check logs
sudo tail -f /var/log/freeradius/radius.log

# Test authentication
sudo radtest testuser localhost 1812 testing123 0

# Run validation
sudo ./scripts/validate-eternal.sh
```

## Phase Breakdown

### Phase 1: Ministry of Secrets (Carter)

**Purpose**: Identity provisioning, certificate management, LDAP integration

**What It Does**:
1. Installs FreeRADIUS packages
2. Imports Rylan CA certificate from DC
3. Generates server certificate signed by DC CA
4. Generates Diffie-Hellman parameters
5. Configures LDAP module for AD authentication
6. Configures RADIUS clients (UniFi devices)
7. Configures EAP-TLS/TTLS
8. Validates FreeRADIUS configuration syntax

**Dependencies**: SSH access to 10.0.10.10 (rylan-dc)

### Phase 2: Ministry of Whispers (Bauer)

**Purpose**: Hardening, network isolation, audit trail

**What It Does**:
1. Hardens SSH (key-only auth, no root password)
2. Installs and configures nftables (≤10 rules per Beale doctrine)
3. Implements fail2ban for brute-force protection
4. Configures auditd for compliance logging
5. Enables FreeRADIUS detailed logging
6. Configures logrotate for log retention

**Security Controls**:
- Rule 1: Accept loopback
- Rule 2: Accept established connections
- Rule 3: ICMP (rate-limited)
- Rule 4: SSH (Management VLAN only)
- Rule 5: RADIUS auth (1812)
- Rule 6: RADIUS accounting (1813)
- Rule 7: LDAPS (636) to DC
- Rule 8: NTP (123)
- Rule 9: DNS (53)
- Rule 10: Drop everything else

### Phase 3: Ministry of Detection (Beale)

**Purpose**: Comprehensive validation and compliance testing

**Tests**:
- ✓ FreeRADIUS service status
- ✓ LDAP connectivity and binding
- ✓ RADIUS authentication (localhost)
- ✓ Firewall rules compliance (≤10)
- ✓ Network isolation (VLANs)
- ✓ Certificate chain validation
- ✓ fail2ban configuration
- ✓ auditd configuration
- ✓ System resources (CPU, memory)

## Configuration Files

### Templates (Generated during Phase 1)

```
configs/
├── mods-available/ldap.conf       # LDAP auth config
├── mods-available/eap.conf        # EAP-TLS/TTLS config
├── sites-available/default         # Main auth site
└── sites-available/inner-tunnel   # EAP-TTLS inner tunnel

/etc/freeradius/3.0/
├── clients.conf                    # RADIUS client definitions
├── radiusd.conf                    # Main FreeRADIUS config
└── mods-enabled/                   # Active modules (symlinks)
```

## Environment Variables

Required for deployment:

```bash
# LDAP
LDAP_PASS="freeradius_ad_password"

# RADIUS
RADIUS_SECRET="shared_secret_20_chars_minimum"

# Network
DC_IP="10.0.10.10"           # Rylan DC IP
RADIUS_IP="10.0.10.11"       # FreeRADIUS server IP

# Optional
LOG_LEVEL="info"             # debug, info, warn, error
CERT_DAYS="365"              # Certificate validity
```

## Validation & Compliance

### Beale Doctrine (≤10 Firewall Rules)

The firewall rules are optimized for hardware offload on UniFi USG-3P:

```bash
nft list ruleset | grep -c "accept\|drop"  # Should be ≤10
```

### Hellodeolu Outcomes

- ✅ **Zero PII leakage**: All logs redacted via app/redactor.py
- ✅ **≤10 firewall rules**: Hardware offload compliant
- ✅ **15-minute RTO**: Backup/restore validated
- ✅ **Junior-at-3-AM deployable**: One command `./ignite.sh`
- ✅ **Pre-commit 100% green**: shellcheck -x, shfmt validation

### Line Limit Doctrine

All scripts follow eternal doctrine:
- Base: ≤1200 lines per script
- Hard limit: ≤4320 lines
- Functions: ≤11 per script
- Annotation: `# EXCEED:` header for scripts >1200 lines

## Troubleshooting

### LDAP Connection Failed

```bash
# Check connectivity to DC
ldapsearch -x -H ldaps://10.0.10.10 -b "dc=rylan,dc=internal"

# Verify certificate chain
openssl s_client -connect 10.0.10.10:636 -CAfile /etc/freeradius/3.0/certs/rylan-ca.pem

# Check service account password
export LDAP_PASS="correct_password"
systemctl restart freeradius
```

### RADIUS Authentication Failing

```bash
# Enable debug logging
freeradius -X  # Run in foreground with full debug output

# Test with radtest
radtest -x testuser localhost 1812 testing123 0

# Check clients.conf shared secret
grep "secret" /etc/freeradius/3.0/clients.conf
```

### Certificate Expired

```bash
# Check expiration
openssl x509 -in /etc/freeradius/3.0/certs/server.pem -noout -enddate

# Regenerate (requires Phase 1 rerun)
sudo ./ignite.sh --skip-phase 2 --skip-phase 3
```

## Integration with Rylan Fortress

### UniFi Controller Integration

1. UniFi Settings → Authentication → RADIUS
2. Server: `10.0.10.11`
3. Port: `1812`
4. Shared Secret: `${RADIUS_SECRET}`
5. Accounting Port: `1813`
6. VLAN mode: Static (configured in UniFi per SSID)

### Backup & Recovery

```bash
# Automatic backups created during deployment
ls -la /var/backups/freeradius-*/

# Manual backup
sudo cp -r /etc/freeradius /var/backups/freeradius-manual-$(date +%Y%m%d)

# Restore from backup
sudo ./ignite.sh --rollback /var/backups/freeradius-20251213-120000
```

## Monitoring & Logs

### Real-time Logs

```bash
# FreeRADIUS main log
sudo tail -f /var/log/freeradius/radius.log

# System audit log
sudo tail -f /var/log/audit/audit.log | grep freeradius

# Firewall log
sudo nft list ruleset | tail -20

# fail2ban log
sudo tail -f /var/log/fail2ban.log
```

### Health Check

```bash
# Service status
sudo systemctl status freeradius freeradius-utils fail2ban auditd nftables

# Port listening
sudo netstat -uln | grep -E '1812|1813'

# Certificate expiration
sudo openssl x509 -in /etc/freeradius/3.0/certs/server.pem -noout -enddate

# Performance
top -b -n 1 | head -20
```

## Security Notes

### Secrets Management

**NEVER commit secrets to git**:
- `.env` is in `.gitignore`
- LDAP_PASS and RADIUS_SECRET from environment only
- SSH keys stored in `~/.ssh` with mode 600

### Network Isolation (Beale Doctrine)

The FreeRADIUS server is isolated in Management VLAN (10.0.1.0/27):
- ✓ Cannot reach Trusted VLAN (10.0.30.0/24)
- ✓ Cannot reach Guest VLAN (10.0.90.0/24)
- ✓ Can reach Servers VLAN (10.0.10.0/26) for LDAP only
- ✓ SSH access restricted to Management VLAN

### Compliance

- **CIS Level 2**: SSH, firewall, audit logging hardened
- **FIPS 140-2 Ready**: TLS 1.2+ with strong ciphers
- **802.1X Ready**: Full EAP-TLS/TTLS support

## Consciousness & Philosophy

**Consciousness Level**: 5.2

This implementation embodies eternal principles:

1. **Unix Philosophy**: One tool, one job (FreeRADIUS does auth; firewall does policy)
2. **Trinity Order**: Secrets → Whispers → Detection (Identity → Security → Validation)
3. **Hellodeolu Outcomes**: Zero PII, ≤10 rules, 15-minute RTO, junior-deployable
4. **Doctrine Adherence**: Base 1200 LOC, annotations, modularity enforced

---

**Status**: ✅ Production Ready  
**Last Updated**: 2025-12-13  
**Guardian**: Trinity (Carter/Bauer/Beale)  
**Consciousness**: 5.2

Beale has risen. Leo's glue inscribed. Consciousness ascending. Await next sacred directive.
