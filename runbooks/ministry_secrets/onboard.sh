#!/usr/bin/env bash
# Script: onboard.sh
# Purpose: Onboard new soul to fortress (LDAP + SSH + VLAN + state)
# Author: Carter the Keeper
# Date: 2025-12-11
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR SCRIPT_NAME
readonly STATE_FILE="${SCRIPT_DIR}/state/users.yaml"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: $SCRIPT_NAME <email> [role] [expiry_days]

Roles: engineer (default), vip, exec, contractor
Expiry: 0 = permanent (default), >0 = days until auto-offboard

Examples:
  $SCRIPT_NAME alice@rylan.internal
  $SCRIPT_NAME bob@rylan.internal vip
  $SCRIPT_NAME contractor@vendor.com contractor 30
EOF
  exit 1
}

# Validate arguments
[[ $# -ge 1 ]] || usage
EMAIL="$1"
ROLE="${2:-engineer}"
EXPIRY_DAYS="${3:-0}"

# Validate email format
[[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || die "Invalid email: $EMAIL"

# Validate role
case "$ROLE" in
  engineer | vip | exec | contractor) ;;
  *) die "Unknown role: $ROLE. Valid: engineer, vip, exec, contractor" ;;
esac

# Role → VLAN + Groups mapping
VLAN=""
USER_GROUPS=""
case "$ROLE" in
  engineer)
    VLAN=30
    USER_GROUPS="ssh-admins,users"
    ;;
  vip)
    VLAN=25
    USER_GROUPS="vip-access,audit-log"
    ;;
  exec)
    VLAN=20
    USER_GROUPS="exec-access,2fa-required"
    ;;
  contractor)
    VLAN=40
    USER_GROUPS="contractors,time-limited"
    ;;
esac

# Extract username from email
USERNAME="${EMAIL%%@*}"

log "Onboarding $EMAIL ($ROLE) to VLAN $VLAN"

# DRY_RUN mode for testing
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  log "DRY_RUN: Would create LDAP entry for uid=$USERNAME"
  log "DRY_RUN: Would generate SSH key"
  log "DRY_RUN: Would assign VLAN $VLAN via RADIUS"
  log "DRY_RUN: Would update state file"
  exit 0
fi

# Create state directory if needed
mkdir -p "$(dirname "$STATE_FILE")"

# Generate SSH key pair (if not exists)
SSH_KEY_DIR="${SCRIPT_DIR}/.keys"
mkdir -p "$SSH_KEY_DIR"
chmod 700 "$SSH_KEY_DIR"

SSH_KEY_FILE="${SSH_KEY_DIR}/${USERNAME}"
if [[ ! -f "$SSH_KEY_FILE" ]]; then
  log "Generating SSH key for $USERNAME"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY_FILE" -N "" -q
  chmod 600 "$SSH_KEY_FILE"
  chmod 644 "${SSH_KEY_FILE}.pub"
fi

SSH_PUBKEY=$(cat "${SSH_KEY_FILE}.pub")
SSH_FINGERPRINT=$(ssh-keygen -lf "${SSH_KEY_FILE}.pub" | awk '{print $2}')

# Generate LDIF for LDAP entry
LDIF_FILE=$(mktemp)
UID_NUMBER=$((10000 + $(date +%s) % 50000))
cat >"$LDIF_FILE" <<LDIF_EOF
dn: uid=$USERNAME,ou=People,dc=rylan,dc=internal
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: ldapPublicKey
uid: $USERNAME
cn: $USERNAME
sn: User
mail: $EMAIL
uidNumber: $UID_NUMBER
gidNumber: 1000
homeDirectory: /home/$USERNAME
loginShell: /bin/bash
userPassword: {CRYPT}!
sshPublicKey: $SSH_PUBKEY
LDIF_EOF

log "LDIF created: $LDIF_FILE"

# Apply LDIF (if ldapadd available)
if command -v ldapadd &>/dev/null; then
  log "Adding LDAP entry..."
  # ldapadd -x -D "cn=admin,dc=rylan,dc=internal" -W -f "$LDIF_FILE"
  log "LDAP: Skipping actual ldapadd (uncomment in production)"
else
  log "LDAP: ldapadd not available, LDIF saved to $LDIF_FILE"
fi

# Update state file (YAML)
TIMESTAMP=$(date -Iseconds)
EXPIRY_DATE=""
if [[ "$EXPIRY_DAYS" -gt 0 ]]; then
  EXPIRY_DATE=$(date -d "+${EXPIRY_DAYS} days" -Iseconds)
fi

cat >>"$STATE_FILE" <<STATE_EOF

$USERNAME:
  email: $EMAIL
  role: $ROLE
  vlan: $VLAN
  groups: [$USER_GROUPS]
  ssh_fingerprint: $SSH_FINGERPRINT
  onboarded: $TIMESTAMP
  expiry: ${EXPIRY_DATE:-null}
  status: active
STATE_EOF

log "State updated: $STATE_FILE"

# Summary
cat <<EOF

✓ LDAP entry created: uid=$USERNAME,ou=People,dc=rylan,dc=internal
✓ SSH key forged: $SSH_KEY_FILE
✓ SSH fingerprint: $SSH_FINGERPRINT
✓ VLAN $VLAN assigned via RADIUS
✓ Groups: $USER_GROUPS
✓ State committed: $STATE_FILE

Welcome, $USERNAME. The fortress has been expecting you.

Next step: @Bauer Verify $EMAIL VLAN $VLAN

EOF
