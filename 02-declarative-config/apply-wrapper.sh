#!/usr/bin/env bash
# 02-declarative-config/apply-wrapper.sh — Canonical Heresy Wrapper for apply.py
# Purpose: Contain declarative config application in battle-tested wrapper
# Canon: DT/Luke Smith + Hellodeolu v6 + T3-ETERNAL Trinity
# Wrapper: ≤19 lines | Python: mypy --strict, bandit clean, pytest ≥93%

set -euo pipefail
IFS=$'\n\t'
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

# shellcheck disable=SC2155
# shellcheck disable=SC1091

# Source UniFi credentials
source "${SCRIPT_DIR}/../.secrets/unifi-env" || die "Missing vault: .secrets/unifi-env"

log "Starting declarative config application — Heresy #1: GitOps enforcement"

# Pre-flight: Validate config files exist
[[ -f "${SCRIPT_DIR}/policy-table-rylan-v5.json" ]] || die "Policy table missing"
[[ -f "${SCRIPT_DIR}/vlans.yaml" ]] || die "VLANs config missing"

# Execute the Python payload
exec python3 "${SCRIPT_DIR}/apply.py" "$@"
