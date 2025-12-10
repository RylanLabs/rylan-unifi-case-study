#!/usr/bin/env bash
# 01-bootstrap/proxmox/01-proxmox-hardening/vm-cloudinit-eject.sh — Leo's Proxmox VM ascension
# T3-ETERNAL v∞.3.2 · Cloud-init bootstrap + post-provision CD-ROM eject

set -euo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2034  # SCRIPT_DIR reserved for template compliance
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034  # SCRIPT_DIR/SCRIPT_NAME reserved for downstream sourcing
readonly SCRIPT_DIR SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

main() {
  local vm_id cloud_init_iso cicustom_user vm_name vm_ip
  vm_id="${1:-}"
  cloud_init_iso="${2:-/var/lib/vz/template/iso/ubuntu-24.04-cloudinit.iso}"
  cicustom_user="${3:-local:iso/samba-ad-dc-user-data.yaml}"
  [[ -n "${vm_id}" ]] || die "Usage: ${SCRIPT_NAME} <vm_id> [iso_path] [user_data]"
  vm_name="rylan-${vm_id}"
  vm_ip="10.0.10.${vm_id}0"

  # CI_MODE: skip live Proxmox actions
  if [[ "${CI_MODE:-}" == "1" ]]; then
    log "CI_MODE=1 detected — skipping qm provisioning and nmap"
    log "Simulated success for VM ${vm_id} (${vm_ip})"
    return 0
  fi

  local qm_bin nmap_bin
  qm_bin="${QM_BIN:-qm}"
  nmap_bin="${NMAP_BIN:-nmap}"
  command -v "${qm_bin}" >/dev/null || die "${qm_bin} not found"
  command -v "${nmap_bin}" >/dev/null || die "${nmap_bin} not found"

  [[ -f "${cloud_init_iso}" ]] || die "ISO not found: ${cloud_init_iso}"
  [[ -f "/var/lib/vz/${cicustom_user#local:}" ]] || die "User-data missing: ${cicustom_user}"

  if ${qm_bin} status "${vm_id}" &>/dev/null; then
    log "WARN: VM ${vm_id} exists — skipping provision"
    return 0
  fi

  log "Creating VM ${vm_name} with cloud-init ISO ${cloud_init_iso}"
  ${qm_bin} create "${vm_id}" \
    --name "${vm_name}" \
    --cores 2 --memory 4096 \
    --net0 virtio,bridge=vmbr0 \
    --scsi0 rpool:32 \
    --boot order=scsi0;ide2 \
    --ide2 "${cloud_init_iso},media=cdrom" \
    --cicustom user="${cicustom_user}" \
    --ipconfig0 ip="${vm_ip}"/26,gw=10.0.10.1 \
    --agent enabled=1

  log "Starting VM ${vm_id} and waiting for cloud-init..."
  if ! timeout 120 bash -c "until ${qm_bin} guest exec ${vm_id} -- test -f /var/lib/cloud/instance/boot-finished 2>/dev/null; do sleep 5; done"; then
    log "WARN: Cloud-init timeout — proceeding to eject CD-ROM"
  fi

  log "Ejecting cloud-init CD-ROM to prevent boot loops"
  ${qm_bin} set "${vm_id}" --ide2 none
  ${qm_bin} set "${vm_id}" --boot order=scsi0

  log "Running Whitaker nmap check on ${vm_ip} (top 100 ports)"
  local nmap_output open_count max_open
  max_open="${MAX_OPEN_PORTS:-6}"
  nmap_output="$(${nmap_bin} -Pn --top-ports 100 "${vm_ip}" 2>/dev/null)"
  open_count="$(printf '%s' "${nmap_output}" | grep -c "open")"
  if [[ "${open_count}" -gt "${max_open}" ]]; then
    printf '%s\n' "${nmap_output}" >&2
    die "Unexpected open ports detected (${open_count})"
  fi
  log "✓ CD-ROM ejected and port surface minimal (open ports: ${open_count}, threshold: ${max_open})"
  log "Leo's ascension complete: VM ${vm_id} online at ${vm_ip}"
}

main "$@"
