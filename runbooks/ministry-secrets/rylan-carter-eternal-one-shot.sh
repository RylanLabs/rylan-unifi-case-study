#!/usr/bin/env bash
# runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
# Carter Ministry: Identity is Programmable Infrastructure (RFC-2307)
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2155
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2155
readonly SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

readonly SECRETS_FILE="${SCRIPT_DIR}/../../.secrets/samba-admin-pass"
[[ -f "${SECRETS_FILE}" ]] || die "Vault missing: .secrets/samba-admin-pass"
# shellcheck disable=SC2155
readonly SAMBA_ADMIN_PASS="$(<"${SECRETS_FILE}")"

readonly DOMAIN="RYLAN"
readonly REALM="RYLAN.INTERNAL"
readonly DC_IP="10.0.10.10"
readonly DNS_FORWARDER="1.1.1.1"

preflight_checks() {
    log "Carter preflight: validating environment"
    [[ "$(hostname)" == "rylan-dc" ]] || die "Must run on rylan-dc"
    [[ $EUID -eq 0 ]] || die "Must run as root"
    command -v samba-tool >/dev/null || die "Samba not installed"
    if samba-tool domain info 127.0.0.1 2>/dev/null | grep -q "Domain"; then
        log "✓ Samba AD already provisioned (idempotent skip)"; exit 0
    fi
}

provision_samba_ad() {
    log "Provisioning Samba AD/DC with RFC-2307 schema"
    systemctl stop smbd nmbd winbind 2>/dev/null || true
    [[ -f /etc/samba/smb.conf ]] && mv /etc/samba/smb.conf "/etc/samba/smb.conf.backup.$(date +%s)"
    samba-tool domain provision \
        --use-rfc2307 \
        --realm="${REALM}" \
        --domain="${DOMAIN}" \
        --adminpass="${SAMBA_ADMIN_PASS}" \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL \
        --option="dns forwarder = ${DNS_FORWARDER}" || die "Samba provision failed"
}

configure_kerberos() {
    ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf
}

configure_dns() {
    cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
search ${REALM,,}
EOF
    samba-tool dns add 127.0.0.1 "${REALM,,}" rylan-dc A "${DC_IP}" -U Administrator --password="${SAMBA_ADMIN_PASS}" 2>/dev/null || true
}

extend_ldap_schema() {
  cat > /tmp/schema-extend.ldif <<'EOF'
dn: CN=rylan-eternal-schema,CN=Schema,CN=Configuration,DC=rylan,DC=internal
changetype: add
objectClass: top
objectClass: classSchema
cn: rylan-eternal-schema
description: Eternal fortress identity extensions
EOF
  if command -v ldapadd >/dev/null 2>&1; then
    ldapadd -x -D "CN=Administrator,CN=Users,DC=rylan,DC=internal" -w "${SAMBA_ADMIN_PASS}" -f /tmp/schema-extend.ldif 2>/dev/null || true
  fi
  rm -f /tmp/schema-extend.ldif
}

create_service_accounts() {
    for service in unifi osticket grafana radius; do
        samba-tool user create "svc-${service}" "$(openssl rand -base64 24)" --description="Service account for ${service}" -U Administrator --password="${SAMBA_ADMIN_PASS}" 2>/dev/null || true
    done
}

enable_services() {
    systemctl unmask samba-ad-dc 2>/dev/null || true
    systemctl enable samba-ad-dc
    systemctl restart samba-ad-dc || die "Failed to start samba-ad-dc"
    local retries=30
    while [[ ${retries} -gt 0 ]]; do
        samba-tool domain info 127.0.0.1 2>/dev/null | grep -q "Domain" && break
        sleep 2; retries=$((retries - 1))
    done
    [[ ${retries} -eq 0 ]] && die "Samba AD/DC failed to start"
}

validate_provision() {
    samba-tool domain info 127.0.0.1 | grep -q "${REALM}" || die "Domain info failed"
    nslookup rylan-dc."${REALM,,}" 127.0.0.1 | grep -q "${DC_IP}" || die "DNS resolution failed"
    echo "${SAMBA_ADMIN_PASS}" | kinit Administrator@"${REALM}" 2>/dev/null || die "Kerberos auth failed"
    kdestroy 2>/dev/null || true
}

main() {
    log "════════════════ Carter Ministry — Identity Programmable ════════════════"
    preflight_checks
    provision_samba_ad
    configure_kerberos
    configure_dns
    extend_ldap_schema
    create_service_accounts
    enable_services
    validate_provision
    log "✓ CARTER MINISTRY COMPLETE — Identity operational at ${DC_IP} (${REALM})"
    log "Next: Execute Bauer ministry (SSH/sudo hardening)"
}

main "$@"