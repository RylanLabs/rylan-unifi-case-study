#!/usr/bin/env bash
set -euo pipefail
# Script: validate-eternal.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# Wrapper to keep legacy entrypoint while enforcing scripts/ location.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${ROOT_DIR}/scripts/validate-eternal.sh" "$@"
