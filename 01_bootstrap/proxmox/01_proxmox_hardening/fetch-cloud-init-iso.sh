#!/usr/bin/env bash
# 01-bootstrap/proxmox/01-proxmox-hardening/fetch-cloud-init-iso.sh — Stage Ubuntu 24.04 cloud-init ISO
# Downloads ISO if missing, optional SHA256 verification (ISO_SHA256 env)

set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034  # retained for template compliance
readonly SCRIPT_DIR SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() {
  log "ERROR: $*" >&2
  exit 1
}

main() {
  local iso_path iso_dir iso_url tmp_file
  iso_path="${1:-/var/lib/vz/template/iso/ubuntu-24.04-cloudinit.iso}"
  iso_dir="$(dirname "${iso_path}")"
  iso_url="${ISO_URL:-https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso}"
  tmp_file="${iso_dir}/.tmp-cloudinit.iso"

  if [[ "${CI_MODE:-}" == "1" ]]; then
    log "CI_MODE=1 — skipping ISO fetch"
    return 0
  fi

  command -v wget >/dev/null || die "wget not found"
  command -v sha256sum >/dev/null || log "WARN: sha256sum not found — checksum skipped"

  mkdir -p "${iso_dir}"

  if [[ -f "${iso_path}" ]]; then
    if [[ -n "${ISO_SHA256:-}" ]] && command -v sha256sum >/dev/null; then
      if echo "${ISO_SHA256}  ${iso_path}" | sha256sum -c --status; then
        log "ISO present and checksum valid — nothing to do"
        return 0
      fi
      log "WARN: ISO exists but checksum mismatch — re-downloading"
    else
      log "ISO already present — checksum skipped"
      return 0
    fi
  fi

  log "Downloading cloud-init ISO from ${iso_url}"
  wget -O "${tmp_file}" "${iso_url}"

  if [[ -n "${ISO_SHA256:-}" ]] && command -v sha256sum >/dev/null; then
    echo "${ISO_SHA256}  ${tmp_file}" | sha256sum -c --status || die "Checksum validation failed for ${tmp_file}"
    log "Checksum verified"
  else
    log "Checksum skipped (ISO_SHA256 not provided)"
  fi

  mv "${tmp_file}" "${iso_path}"
  log "ISO staged at ${iso_path}"
}

main "$@"
