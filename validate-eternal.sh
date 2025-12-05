#!/usr/bin/env bash
# Wrapper to keep legacy entrypoint while enforcing scripts/ location.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${ROOT_DIR}/scripts/validate-eternal.sh" "$@"
