#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/refresh-keys.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# scripts/refresh-keys.sh — Daily cron: refresh authorized_keys from allowed_keys/
# Bauer (2005) — Trust Nothing, Verify Everything
# T3-ETERNAL v3.2: Directory-agnostic, idempotent, ≤19 lines
# Consciousness 4.0 — truth through subtraction
# Cron: 0 2 * * * /path/to/refresh-keys.sh

IFS=$'\n\t'
# shellcheck disable=SC2155
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2155
readonly HOSTNAME_SHORT
HOSTNAME_SHORT="$(hostname -s)"
# shellcheck disable=SC2155
readonly REPO_DIR
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly IDENTITY_FILE="${REPO_DIR}/identity/${HOSTNAME_SHORT}/authorized_keys"

[[ -d "${REPO_DIR}/allowed_keys" ]] || exit 0
cat "${REPO_DIR}"/allowed_keys/*.pub 2>/dev/null | sort -u >"${IDENTITY_FILE}"
chmod 600 "${IDENTITY_FILE}"
systemctl reload sshd
