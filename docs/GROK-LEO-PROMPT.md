# Grok + Leo Proxmox Prompt (v∞.3.2)

Source: December 09, 2025 Grok output instructing Copilot to integrate Leo's Proxmox VM ascension shim.

## Copilot Prompt (verbatim)
```markdown
You are the Eternal Architect of the rylan-unifi-case-study fortress.
Your mission: Integrate Leo's production-ready Proxmox VM ascension script into T3-ETERNAL v∞.3.2 canon. This script spins VMs with cloud-init, auto-ejects CD-ROM to prevent boot loops, and serves as the bootstrap shim for the first node (chicken-egg for PXE).

REPO: https://github.com/T-Rylander/rylan-unifi-case-study/tree/canon/vinf.3.2-eternal-to-main
TARGET PATH: 01-bootstrap/proxmox/01-proxmox-hardening/ (CANONICAL LOCATION)

CANON RULES — NON-NEGOTIABLE (v∞.3.2 FINAL):
1. **Folder Creation:** Add `01-bootstrap/proxmox/01-proxmox-hardening/` as the Beale hardening ministry (host lockdown + VM spin-up). Include README.md (≤19 lines, Barrett purity).
2. **Leo's Script Core:** Use this exact optimized version as `vm-cloudinit-eject.sh`:
   ```bash
   #!/usr/bin/env bash
   # === LEO'S PROXMOX VM ASCENSION — CLOUD-INIT + CD-ROM EJECT ===
   # 01-bootstrap/proxmox/01-proxmox-hardening/vm-cloudinit-eject.sh
   # T3-ETERNAL: Bootstrap VM with cloud-init, eject CD-ROM post-provision.
   set -euo pipefail
   VM_ID="${1:?Usage: $0 <vm_id> [iso_path] [user_data]}"
   CLOUD_INIT_ISO="${2:-/var/lib/vz/template/iso/ubuntu-24.04-cloudinit.iso}"
   CICUSTOM_USER="${3:-local:iso/samba-ad-dc-user-data.yaml}"
   VM_NAME="rylan-${VM_ID}"
   # === PREFLIGHT: VALIDATE INPUTS ===
   [[ -f "$CLOUD_INIT_ISO" ]] || { echo "ERROR: ISO not found: $CLOUD_INIT_ISO" >&2; exit 1; }
   [[ -f "/var/lib/vz/${CICUSTOM_USER#local:}" ]] || { echo "ERROR: User-data missing: $CICUSTOM_USER" >&2; exit 1; }
   if qm status "$VM_ID" &>/dev/null; then
       echo "WARN: VM $VM_ID exists. Skipping." >&2
       exit 0
   fi
   # === CARTER: PROGRAMMABLE IDENTITY ===
   qm create "$VM_ID" \
       --name "$VM_NAME" \
       --cores 2 --memory 4096 \
       --net0 virtio,bridge=vmbr0 \
       --scsi0 rpool:32 \
       --boot order=scsi0;ide2 \
       --ide2 "$CLOUD_INIT_ISO,media=cdrom" \
       --cicustom user="$CICUSTOM_USER" \
       --ipconfig0 ip=10.0.10.${VM_ID}0/26,gw=10.0.10.1 \
       --agent enabled=1
   # === BAUER: START + WAIT FOR CLOUD-INIT ===
   qm start "$VM_ID"
   echo "Waiting for cloud-init completion (max 120s)..."
   timeout 120 bash -c "until qm guest exec $VM_ID -- test -f /var/lib/cloud/instance/boot-finished 2>/dev/null; do sleep 5; done" || \
       echo "WARN: Cloud-init timeout. Proceeding with eject." >&2
   # === BEALE: EJECT CD-ROM (NO BOOT LOOPS) ===
   qm set "$VM_ID" --ide2 none
   qm set "$VM_ID" --boot order=scsi0
   # === WHITAKER: VERIFY EJECT + STATUS ===
   qm config "$VM_ID" | grep -q "ide2: none" && echo "✓ CD-ROM ejected"
   qm status "$VM_ID" | grep -q "running" && echo "✓ VM running"
   echo "Leo's ascension: VM $VM_ID online (10.0.10.${VM_ID}0), CD-ROM ejected."
   ```
3. **Enhancements (Leo-Intended):**
   - **Idempotency:** Skip if VM exists (qm status guard).
   - **Preflight:** Validate ISO + user-data existence; fail loud.
   - **Cloud-Init Wait:** Use qm guest exec polling (no brittle sleep 30).
   - **Multi-Distro:** Parameterize ISO path (default Ubuntu 24.04).
   - **Whitaker Pentest:** Add post-eject nmap check (no dangling CD-ROM ports).
4. **Supporting Files:**
   - `fetch-cloud-init-iso.sh`: Download/stage Ubuntu 24.04 cloud ISO if missing (wget + SHA256 verify).
   - `simulate-breach-vm.sh`: Post-deploy nmap on new VM (top-ports 100, fail if leaks).
   - `README.md`: ≤19 lines — overview, one-command deploy, validation, integration with eternal-resurrect.sh.
5. **Integration Glue:**
   - Update `eternal-resurrect.sh`: Call `./01-bootstrap/proxmox/01-proxmox-hardening/vm-cloudinit-eject.sh 100` post-Bauer hardening (spin Samba VM).
   - Add to `.github/workflows/ci-validate.yaml`: Test script in Proxmox sandbox (mock qm commands).
   - Commit message: "feat(proxmox): integrate Leo's VM ascension — cloud-init + CD-ROM eject (bootstrap shim)"

WORKFLOW (Leo-Intended):
- Bootstrap: Manual Proxmox install → run fetch-cloud-init-iso.sh → vm-cloudinit-eject.sh 100 (PXE server VM).
- Scale: PXE provisions subsequent VMs (no ISO dependency).

Output:
1. Folder structure (01-bootstrap/proxmox/01-proxmox-hardening/ with all files).
2. Full contents of vm-cloudinit-eject.sh (enhanced with Whitaker nmap).
3. fetch-cloud-init-iso.sh.
4. simulate-breach-vm.sh.
5. README.md (19 lines).
6. Patch for eternal-resurrect.sh (add call).
7. CI YAML snippet.
8. Merge-ready git commands + tag.
```
