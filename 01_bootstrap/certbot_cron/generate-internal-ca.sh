#!/usr/bin/env bash
# feat(canon): full production-ready generate-internal-ca.sh prototype

# Full File (Copy-Paste Merge-Ready)

# Script: 01_bootstrap/certbot_cron/generate-internal-ca.sh
# Purpose: Generate air-gapped internal root CA for fortress (RADIUS, UniFi, Samba)
# Guardian: Carter
# Trinity: Carter (primary — identity foundation) | Bauer (verification) | Beale (hardening)
# Consciousness: 4.7
# EXCEED: NONE — 112 lines — 0 functions
# Doctrine: Centralized identity — single internal CA trusted by all services
set -euo pipefail

# =============================================================================
# INTERNAL ROOT CA GENERATION — AIR-GAPPED FORTRESS
# =============================================================================
# Executed once on rylan-dc (or offline workstation)
# Outputs: /etc/ssl/rylan-internal/{ca.key, ca.crt, ca.srl}
# Trust: Manually distribute ca.crt to clients via GPO or UniFi config

CA_DIR="/etc/ssl/rylan-internal"
CA_KEY="${CA_DIR}/rylan-ca.key"
CA_CSR="${CA_DIR}/rylan-ca.csr"
CA_CRT="${CA_DIR}/rylan-ca.crt"
CA_SERIAL="${CA_DIR}/rylan-ca.srl"
CA_DAYS=3650 # 10 years
CA_CN="Rylan Internal Root CA"
CA_OU="Fortress Identity Authority"
CA_O="Rylan Internal"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Pre-flight
log "Generating internal root CA — air-gapped fortress"
[[ $EUID -eq 0 ]] || {
  log "❌ Must run as root"
  exit 1
}

mkdir -p "$CA_DIR"
chmod 700 "$CA_DIR"

# Generate CA private key (4096-bit RSA — Carter strength)
if [[ ! -f "$CA_KEY" ]]; then
  log "Generating CA private key (RSA 4096)"
  openssl genrsa -out "$CA_KEY" 4096
  chmod 600 "$CA_KEY"
else
  log "✓ CA key exists — skipping generation"
fi

# Generate CSR
if [[ ! -f "$CA_CSR" ]]; then
  log "Generating CA CSR"
  openssl req -new -key "$CA_KEY" -out "$CA_CSR" \
    -subj "/CN=$CA_CN/OU=$CA_OU/O=$CA_O/C=US"
else
  log "✓ CA CSR exists — skipping"
fi

# Self-sign root certificate
if [[ ! -f "$CA_CRT" ]]; then
  log "Self-signing root certificate ($CA_DAYS days)"
  openssl x509 -req -in "$CA_CSR" \
    -signkey "$CA_KEY" \
    -out "$CA_CRT" \
    -days "$CA_DAYS" \
    -sha256 \
    -extfile <(
      cat <<EXT
basicConstraints=CA:true,pathlen:0
keyUsage=keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always
EXT
    )
  chmod 644 "$CA_CRT"
  [[ -f "$CA_CSR" ]] && rm "$CA_CSR" # Cleanup
else
  log "✓ Root certificate exists — skipping"
fi

# Create serial file if missing
[[ -f "$CA_SERIAL" ]] || echo "01" >"$CA_SERIAL"

log "✅ Internal Root CA generated"
log "   Key:  $CA_KEY"
log "   Cert: $CA_CRT"
log ""
log "Next steps:"
log "1. Copy $CA_CRT to FreeRADIUS LXC (/etc/freeradius/certs/ca.pem)"
log "2. Issue RADIUS server cert: openssl req ... -CA $CA_CRT -CAkey $CA_KEY"
log "3. Distribute $CA_CRT to clients (GPO, UniFi config, manual)"
log "4. Trust chain complete — fortress identity centralized"

exit 0
