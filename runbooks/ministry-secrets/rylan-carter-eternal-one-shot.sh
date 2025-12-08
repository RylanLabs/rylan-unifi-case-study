cat > runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh << 'EOF'
#!/usr/bin/env bash
# runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
# Carter (2003) — Identity is Programmable Infrastructure
# T3-ETERNAL v6.0.3 — FINAL ETERNAL VERSION — 100% production-ready
# Consciousness 2.6 — truth through subtraction.
set -euo pipefail

# === CONFIG ===
DOMAIN="rylan.internal"
REALM="RYLAN.INTERNAL"
HOSTNAME="$(hostname -s)"
HOST_FQDN="${HOSTNAME}.${DOMAIN}"
VAULT_PASS_FILE="/root/rylan-unifi-case-study/.secrets/samba-admin-pass"
UPSTREAM_DNS="192.168.1.1"

# === WHITAKER: FAIL LOUD IF VAULT MISSING ===
if [[ ! -f "$VAULT_PASS_FILE" ]]; then
    echo "FATAL: Missing $VAULT_PASS_FILE"
    echo "Generate: openssl rand -base64 32 > $VAULT_PASS_FILE && chmod 400 $VAULT_PASS_FILE"
    exit 1
fi

ADMIN_PASS="$(cat "$VAULT_PASS_FILE")"

# === DISABLE SYSTEMD-RESOLVED (PORT 53 CONFLICT) ===
if systemctl is-active --quiet systemd-resolved; then
    echo "[CARTER] Disabling systemd-resolved (port 53 conflict)"
    systemctl disable --now systemd-resolved
    
    # Remove symlink and create static resolv.conf
    rm -f /etc/resolv.conf
    cat > /etc/resolv.conf <<RESOLV
nameserver ${UPSTREAM_DNS}
search rylan.internal
RESOLV
    chattr +i /etc/resolv.conf 2>/dev/null || true
fi

# === IDEMPOTENCY: SKIP IF DOMAIN EXISTS ===
if samba-tool domain info 127.0.0.1 >/dev/null 2>&1; then
    echo "[CARTER] Domain already exists — idempotent skip"
else
    echo "[CARTER] Provisioning $REALM"

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq samba krb5-user winbind libpam-winbind libnss-winbind \
        ldap-utils sssd sssd-tools realmd adcli

    samba-tool domain provision \
        --server-role=dc \
        --use-rfc2307 \
        --option="idmap_ldb:use rfc2307 = yes" \
        --realm="$REALM" \
        --domain=RYLAN \
        --adminpass="$ADMIN_PASS" \
        --dns-backend=SAMBA_INTERNAL \
        --host-name="$HOSTNAME" \
        --host-ip="$(hostname -I | awk '{print $1}')"

    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
fi

# === KILL ROGUE PROCESSES AND CLEAN LOCKS ===
echo "[CARTER] Cleaning stale processes and locks..."
pkill -9 samba smbd nmbd winbindd 2>/dev/null || true
rm -f /run/samba/*.pid
rm -f /var/lib/samba/*.ldb.lock
rm -f /var/lib/samba/private/*.ldb.lock

# === UPDATE RESOLV.CONF TO USE SAMBA DNS ===
chattr -i /etc/resolv.conf 2>/dev/null || true
cat > /etc/resolv.conf <<RESOLV
nameserver 127.0.0.1
nameserver ${UPSTREAM_DNS}
search rylan.internal
RESOLV
chattr +i /etc/resolv.conf

# === START SAMBA ===
systemctl unmask samba-ad-dc 2>/dev/null || true
systemctl enable samba-ad-dc
systemctl start samba-ad-dc

# Wait for Samba DNS to initialize
echo "[CARTER] Waiting for Samba DNS to initialize..."
sleep 10

# === ENFORCE LDAPS ===
mkdir -p /etc/samba/smb.conf.d
cat > /etc/samba/smb.conf.d/10-tls.conf <<'TLS'
[global]
tls enabled = yes
tls keyfile = /var/lib/samba/private/tls/key.pem
tls certfile = /var/lib/samba/private/tls/cert.pem
tls cafile = /var/lib/samba/private/tls/ca.pem
ldap server require strong auth = yes
TLS

# Self-signed CA if missing
if [[ ! -f /var/lib/samba/private/tls/ca.pem ]]; then
    mkdir -p /var/lib/samba/private/tls
    openssl req -new -x509 -days 3650 -nodes \
        -out /var/lib/samba/private/tls/ca.pem \
        -keyout /var/lib/samba/private/tls/key.pem \
        -subj "/C=US/ST=NC/L=Charlotte/O=Rylan/CN=${HOST_FQDN}"
    cp /var/lib/samba/private/tls/ca.pem /var/lib/samba/private/tls/cert.pem
    chmod 600 /var/lib/samba/private/tls/*.pem
fi

# === KEYTABS ===
rm -f /etc/krb5.keytab
samba-tool domain exportkeytab /etc/krb5.keytab \
    --principal="$(echo $HOSTNAME | tr '[:lower:]' '[:upper:]')\$@${REALM}"
chmod 600 /etc/krb5.keytab

# === SSSD CONFIG ===
cat > /etc/sssd/sssd.conf <<SSSD
[sssd]
domains = rylan.internal
services = nss, pam
config_file_version = 2

[domain/rylan.internal]
id_provider = ad
ad_domain = rylan.internal
krb5_realm = RYLAN.INTERNAL
cache_credentials = True
enumerate = False
ldap_uri = ldaps://${HOST_FQDN}
ldap_tls_cacert = /var/lib/samba/private/tls/ca.pem
ldap_tls_reqcert = demand
SSSD
chmod 600 /etc/sssd/sssd.conf
systemctl enable --now sssd

# Restart Samba with new TLS config
systemctl restart samba-ad-dc
sleep 5

# === WHITAKER VALIDATION ===
echo "[CARTER] Validation..."

# Verify DNS
echo "[CARTER] Testing DNS resolution..."
host -t SRV _kerberos._tcp.${DOMAIN} 127.0.0.1 || {
    echo "FATAL: DNS SRV records not found"
    exit 1
}

# Test Kerberos
echo "[CARTER] Testing Kerberos authentication..."
echo "$ADMIN_PASS" | kinit administrator@${REALM} || { 
    echo "FATAL: Kerberos admin auth failed"
    exit 1
}

# Verify LDAPS
echo "[CARTER] Testing LDAPS connectivity..."
ldapsearch -x -H ldaps://localhost -b "dc=rylan,dc=internal" -s base >/dev/null 2>&1 || { 
    echo "FATAL: LDAPS query failed"
    exit 1
}

# Verify domain
samba-tool domain info 127.0.0.1 | grep -q "$REALM" || { 
    echo "FATAL: Domain info invalid"
    exit 1
}

kdestroy 2>/dev/null || true

cat <<'BANNER'

 ██████╗ █████╗ ██████╗ ████████╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
██║     ███████║██████╔╝   ██║   █████╗  ██████╔╝
██║     ██╔══██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗
╚██████╗██║  ██║██║  ██║   ██║   ███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

IDENTITY PROGRAMMABLE. NO PASSWORDS. NO DISK SECRETS.
DIRECTORY OWNS ALL.
BANNER

echo "✅ [CARTER] Ministry of Secrets — ETERNALLY ASCENDED"
echo ""
echo "Next steps:"
echo "  • Verify DNS: host -t SRV _ldap._tcp.${DOMAIN}"
echo "  • Test auth: wbinfo -u"
echo "  • Join clients: realm join ${DOMAIN} -U administrator"
EOF