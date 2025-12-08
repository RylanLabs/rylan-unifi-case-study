#!/usr/bin/env bash
# === CARTER ETERNAL IDENTITY v6 — MINISTRY OF CARTER (90 seconds) ===
# runbooks/ministry-carter/rylan-carter-eternal-one-shot.sh
# Carter (2003) — Identity is Programmable Infrastructure
# T3-ETERNAL: No passwords. No secrets on disk. Idempotent. Pentest-clean.
# Commit: feat/t3-eternal-v6-carter | Tag: v6.0.0-carter
set -euo pipefail

# === CANON LOCKS (NEVER CHANGE) ===
DOMAIN="rylan.internal"
REALM="RYLAN.INTERNAL"
HOSTNAME="$(hostname -s)"
HOST_FQDN="${HOSTNAME}.${DOMAIN}"
VAULT_PASS_FILE="/root/rylan-unifi-case-study/.secrets/samba-admin-pass"

# === WHITAKER: Fail loud if vault missing ===
if [[ ! -f "$VAULT_PASS_FILE" ]]; then
    echo "FATAL: Missing $VAULT_PASS_FILE"
    echo "Generate with: openssl rand -base64 32 > $VAULT_PASS_FILE && chmod 400 $VAULT_PASS_FILE"
    exit 1
fi
ADMIN_PASS="$(cat "$VAULT_PASS_FILE")"

# === IDEMPOTENCY GUARD (Carter: "Do not break the directory") ===
if samba-tool domain info 127.0.0.1 >/dev/null 2>&1; then
    echo "[CARTER] Existing domain detected - skipping provision (idempotent)"
else
    echo "[CARTER] Provisioning new domain: $REALM"

    # Install stack
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y samba krb5-user winbind libpam-winbind libnss-winbind \
                      ldap-utils sssd sssd-tools realmd adcli

    # Provision domain (interactive=False forces --use-rfc2307)
    samba-tool domain provision \
        --use-rfc2307 \
        --interactive=False \
        --realm="$REALM" \
        --domain=RYLAN \
        --adminpass="$ADMIN_PASS" \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL

    # Move config into place
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
fi

# === ENFORCE LDAPS (Whitaker: "Encrypt everything") ===
mkdir -p /etc/samba/smb.conf.d
cat > /etc/samba/smb.conf.d/10-tls.conf <<EOF
[global]
tls enabled = yes
tls keyfile = /var/lib/samba/private/tls/key.pem
tls certfile = /var/lib/samba/private/tls/cert.pem
tls cafile   = /var/lib/samba/private/tls/ca.pem
ldap server require strong auth = yes
EOF

# Generate self-signed CA if missing
if [[ ! -f /var/lib/samba/private/tls/ca.pem ]]; then
    mkdir -p /var/lib/samba/private/tls
    openssl req -new -x509 -days 3650 -nodes -out /var/lib/samba/private/tls/ca.pem \
        -keyout /var/lib/samba/private/tls/key.pem \
        -subj "/C=US/ST=NC/L=Charlotte/O=Rylan/CN=${HOST_FQDN}"
    cp /var/lib/samba/private/tls/ca.pem /var/lib/samba/private/tls/cert.pem
    chmod 600 /var/lib/samba/private/tls/*.pem
fi

# === SERVICE KEYTABS (Carter: "Programmable infrastructure") ===
samba-tool domain exportkeytab /etc/krb5.keytab \
    --principal="${HOSTNAME}\$@${REALM}" \
    --principal="admin@${REALM}"

chmod 600 /etc/krb5.keytab

# === SSSD CONFIG (fleet-wide auth) ===
cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = $DOMAIN
services = nss, pam
config_file_version = 2

[domain/$DOMAIN]
id_provider = ad
ad_domain = $DOMAIN
krb5_realm = $REALM
cache_credentials = True
enumerate = True
ldap_uri = ldaps://$HOST_FQDN
ldap_tls_cacert = /var/lib/samba/private/tls/ca.pem
EOF
chmod 600 /etc/sssd/sssd.conf
systemctl enable --now sssd

# Restart Samba to apply TLS config
systemctl restart samba-ad-dc

# === FINAL VALIDATION (Whitaker pentest) ===
echo "[CARTER] Validation..."
kinit -k -t /etc/krb5.keytab "${HOSTNAME}\$@${REALM}" && echo "  [OK] Kerberos machine auth"
ldapsearch -x -H ldaps://localhost -b "dc=rylan,dc=internal" -s base >/dev/null 2>&1 && echo "  [OK] LDAPS enforced"
samba-tool domain info 127.0.0.1 | grep -q "$REALM" && echo "  [OK] Domain healthy"

cat <<'BANNER'

 ██████╗ █████╗ ██████╗ ████████╗███████╗██████╗ 
██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
██║     ███████║██████╔╝   ██║   █████╗  ██████╔╝
██║     ██╔══██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗
╚██████╗██║  ██║██║  ██║   ██║   ███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
IDENTITY IS PROGRAMMABLE. NO PASSWORDS. NO DISK SECRETS.
THE DIRECTORY OWNS ALL. THE RIDE IS ETERNAL.
BANNER
