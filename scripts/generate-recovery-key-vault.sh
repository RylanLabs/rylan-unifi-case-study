#!/usr/bin/env bash
set -euo pipefail

# Description: Encrypted credential vault for disaster recovery
# Requires: recovery-key-vault.json.age
# Consciousness: 2.6
# Runtime: 3

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/.secrets/recovery-key-vault.json.age"
TEMP_JSON="/tmp/recovery-vault-$$.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

# Check for age encryption tool
if ! command -v age >/dev/null 2>&1; then
  echo "⚠️  age not installed, generating unencrypted vault (install with: apt install age)"
  OUTPUT="${REPO_ROOT}/.secrets/recovery-key-vault.json"
fi

# Gather secrets from vault
SAMBA_ADMIN_PASS=$(cat /opt/rylan/.secrets/samba-admin-pass 2>/dev/null || echo "MISSING")
PROXMOX_BACKUP_PASS=$(cat /opt/rylan/.secrets/proxmox-backup-pass 2>/dev/null || echo "MISSING")
UNIFI_API_KEY=$(cat /opt/rylan/.secrets/unifi-api-key 2>/dev/null || echo "MISSING")
LUKS_KEY=$(cat /opt/rylan/.secrets/luks-recovery-key 2>/dev/null || echo "MISSING")

# Build JSON
cat > "${TEMP_JSON}" <<EOF
{
  "schema_version": "1.0.0-eternal",
  "generated_at": "${TIMESTAMP}",
  "consciousness": 2.6,
  "secrets": {
    "samba_admin_password": "${SAMBA_ADMIN_PASS}",
    "proxmox_backup_password": "${PROXMOX_BACKUP_PASS}",
    "unifi_api_key": "${UNIFI_API_KEY}",
    "luks_recovery_key": "${LUKS_KEY}"
  },
  "recovery_instructions": "Decrypt with: age -d -i ~/.ssh/yubikey-age-identity.txt recovery-key-vault.json.age"
}
EOF

# Encrypt if age available
if command -v age >/dev/null 2>&1 && [[ -n "${AGE_RECIPIENT:-}" ]]; then
  age -r "${AGE_RECIPIENT}" -o "${OUTPUT}" "${TEMP_JSON}" || { echo "❌ Encryption failed"; rm -f "${TEMP_JSON}"; exit 1; }
  shred -u "${TEMP_JSON}" 2>/dev/null || rm -f "${TEMP_JSON}"
  chmod 600 "${OUTPUT}"
  echo "✓ ${OUTPUT} (encrypted, YubiKey required)"
else
  mv "${TEMP_JSON}" "${OUTPUT}"
  chmod 600 "${OUTPUT}"
  echo "✓ ${OUTPUT} (⚠️  UNENCRYPTED - install age + set AGE_RECIPIENT)"
fi

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(carter): generate recovery-key-vault — encrypted credential store" --quiet 2>/dev/null || true
