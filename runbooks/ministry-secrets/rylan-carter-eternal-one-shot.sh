#!/usr/bin/env bash
# === CARTER ETERNAL IDENTITY – ONE SHOT (90 seconds) ===
set -euo pipefail

DOMAIN="rylan.local"
REALM="RYLAN.LOCAL"
ADMIN_PASS="$(openssl rand -base64 32)"

# Install identity stack
apt-get update -qq
apt-get install -y slapd ldap-utils samba winbind sssd sssd-tools krb5-user

# Configure OpenLDAP
cat > /etc/ldap/ldap.conf <<EOF
BASE   dc=rylan,dc=local
URI    ldap://localhost
TLS_CACERT /etc/ssl/certs/ca-certificates.crt
EOF

# Bootstrap Samba AD DC
samba-tool domain provision \
  --realm="$REALM" \
  --domain=RYLAN \
  --adminpass="$ADMIN_PASS" \
  --server-role=dc \
  --use-rfc2307

# Configure SSSD for fleet-wide auth
cat > /etc/sssd/sssd.conf <<'EOF'
[sssd]
domains = rylan.local
services = nss, pam
config_file_version = 2

[domain/rylan.local]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://localhost
ldap_search_base = dc=rylan,dc=local
ldap_default_bind_dn = cn=admin,dc=rylan,dc=local
cache_credentials = True
enumerate = True
EOF

chmod 600 /etc/sssd/sssd.conf
systemctl enable --now sssd samba-ad-dc

# Validate identity stack
samba-tool domain info localhost
ldapsearch -x -H ldap://localhost -b "dc=rylan,dc=local" -LLL

echo "$ADMIN_PASS" > /root/.samba-admin-pass
chmod 400 /root/.samba-admin-pass

cat <<'BANNER'

 ██████╗ █████╗ ██████╗ ████████╗███████╗██████╗ 
██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
██║     ███████║██████╔╝   ██║   █████╗  ██████╔╝
██║     ██╔══██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗
╚██████╗██║  ██║██║  ██║   ██║   ███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
IDENTITY FORTRESS ONLINE. SECRETS NEVER SLEEP.
Admin password: /root/.samba-admin-pass
BANNER