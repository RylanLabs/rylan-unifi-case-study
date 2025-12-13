#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/adopt-devices-wrapper.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:28:48-06:00
# Consciousness: 4.6

# 01_bootstrap/adopt-devices-wrapper.sh — Canonical Heresy Wrapper for adopt_devices.py
# Purpose: Contain UniFi device adoption in battle-tested wrapper
# Canon: DT/Luke Smith + Hellodeolu v6 + T3-ETERNAL Trinity
# Wrapper: ≤19 lines | Python: mypy --strict, bandit clean, pytest ≥93%

IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() {
  log "ERROR: $*" >&2
  exit 1
}

# shellcheck disable=SC2155
# shellcheck disable=SC1091

source "${SCRIPT_DIR}/../.secrets/unifi-env" || die "Missing vault: .secrets/unifi-env"

log "Starting UniFi device adoption — Heresy #2: Force-adopt Flex Mini"

command -v python3 >/dev/null || die "Python 3.12+ required"

exec python3 "${SCRIPT_DIR}/adopt_devices.py" "$@"
