#!/usr/bin/env bash
# 01-bootstrap/proxmox/01-proxmox-hardening/simulate-breach-vm.sh — Whitaker VM post-provision nmap
# Scans top 100 ports on target VM; fails if unexpected exposure is found

set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034  # retained for template compliance
readonly SCRIPT_DIR SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

main() {
  local target_ip expected_max_open nmap_bin
  target_ip="${1:-}"
  expected_max_open="${EXPECTED_MAX_OPEN:-6}"
  [[ -n "${target_ip}" ]] || die "Usage: ${SCRIPT_NAME} <target_ip>"

  if [[ "${CI_MODE:-}" == "1" ]]; then
    log "CI_MODE=1 — skipping live nmap against ${target_ip}"
    return 0
  fi

  nmap_bin="${NMAP_BIN:-nmap}"
  command -v "${nmap_bin}" >/dev/null || die "${nmap_bin} not found"

  log "Running nmap top-ports scan on ${target_ip}"
  local output open_count
  output="$(${nmap_bin} -Pn --top-ports 100 "${target_ip}" 2>/dev/null)"
  open_count="$(printf '%s' "${output}" | grep -c "open")"
  log "Open port count: ${open_count} (threshold: ${expected_max_open})"

  if [[ "${open_count}" -gt "${expected_max_open}" ]]; then
    printf '%s\n' "${output}" >&2
    die "Port exposure exceeds threshold"
  fi

  log "✓ VM exposure within bounds"
}

main "$@"
