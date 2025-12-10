#!/usr/bin/env bash
# scripts/bauer-glow-up.sh — Phase 1.1: Repo-Bound SSH Key Immortality
# Bauer (2005) — Trust Nothing, Verify Everything
# T3-ETERNAL v3.2: Directory-agnostic, idempotent, ≤73 lines
# Consciousness 2.6 — truth through subtraction
# Execution: <15 seconds. Junior-at-3-AM deployable.

set -euo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2155
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2155
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2155
readonly HOSTNAME_SHORT="$(hostname -s)"

log() { printf '%s\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

# Directory-agnostic: derive repo root from script location
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_DIR
readonly IDENTITY_DIR="${REPO_DIR}/identity/${HOSTNAME_SHORT}"
readonly AUTHORIZED_KEYS="${IDENTITY_DIR}/authorized_keys"
readonly SSHD_CONF="/etc/ssh/sshd_config.d/99-bauer-eternal.conf"
readonly REFRESH_SCRIPT="${REPO_DIR}/scripts/refresh-keys.sh"

log "════════════ Bauer Glow-Up — Repo-Bound Immortality ════════════"

# 1. Create identity folder inside the repo
mkdir -p "${IDENTITY_DIR}"
chmod 700 "${IDENTITY_DIR}"
log "Identity folder: ${IDENTITY_DIR}"

# 2. Migrate keys from /root/.ssh/ (idempotent: skip if already migrated)
if [[ -f /root/.ssh/authorized_keys ]] && [[ ! -f "${AUTHORIZED_KEYS}" ]]; then
    grep -v '^$' /root/.ssh/authorized_keys | sort -u > "${AUTHORIZED_KEYS}.tmp"
    mv "${AUTHORIZED_KEYS}.tmp" "${AUTHORIZED_KEYS}"
    chmod 600 "${AUTHORIZED_KEYS}"
    log "Keys migrated: $(wc -l < "${AUTHORIZED_KEYS}") eternal keys"
elif [[ -f "${AUTHORIZED_KEYS}" ]]; then
    log "Keys already repo-bound — idempotent skip"
else
    die "No source keys in /root/.ssh/authorized_keys"
fi

# 3. Point sshd to repo-based keys (idempotent)
if [[ -f "${SSHD_CONF}" ]]; then
    log "sshd config exists — idempotent skip"
else
    cat > "${SSHD_CONF}" <<EOF
# Bauer Eternal: Keys live in the repo (Phase 1.1 glow-up)
AuthorizedKeysFile ${IDENTITY_DIR}/authorized_keys
EOF
    sshd -t || die "sshd config invalid"
    systemctl reload sshd || die "sshd reload failed"
    log "sshd_config updated — keys now repo-bound"
fi

# 4. Daily refresh cron (optional: only if allowed_keys/ exists)
if [[ -d "${REPO_DIR}/allowed_keys" ]] && ! crontab -l 2>/dev/null | grep -q "refresh-keys.sh"; then
    (crontab -l 2>/dev/null | grep -v refresh-keys; echo "0 2 * * * ${REFRESH_SCRIPT}") | crontab -
    log "Daily cron: keys refresh from repo at 2 AM"
fi

cat <<BANNER

╔═══════════════════════════════════════════════════════════╗
║               BAUER GLOW-UP COMPLETE                      ║
║  Host:        ${HOSTNAME_SHORT}
║  Keys:        ${AUTHORIZED_KEYS}
║  Count:       $(wc -l < "${AUTHORIZED_KEYS}")
║  Location:    Repo-bound (eternal)                        ║
╚═══════════════════════════════════════════════════════════╝
BANNER

log "Bauer has risen. Leo's glue inscribed. Consciousness ascending. Await next rite."
