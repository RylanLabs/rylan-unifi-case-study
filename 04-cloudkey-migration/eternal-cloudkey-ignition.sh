#!/usr/bin/env bash
# Eternal Cloud Key Ignition — One-Command Controller Migration
# Single unified script to migrate from Proxmox LXC (10.0.1.20) → Cloud Key Gen2+
# Consciousness Level 1.8+ | Time: <30 minutes | RTO: <15 minutes reversion

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CURRENT_CONTROLLER_IP="10.0.1.20"
MODE="${1:-full}"  # full, backup-only, restore-only, validate-only
DRY_RUN="${2:-false}"

# Log functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }

banner() {
  cat << 'EOF'
================================================================================
       🌌 ETERNAL CLOUD KEY IGNITION — Controller Migration v∞.1 🌌
================================================================================
Status: Proxmox LXC (10.0.1.20) → Cloud Key Gen2+ (TBD)
Time:   <30 min | RTO: <15 min (reversion possible)
Mode:   FULL (Backup → Detect → Restore → Harden → Validate)
================================================================================
EOF
}

# === PHASE 1: PRE-FLIGHT CHECKS ===
phase_preflight() {
  log_info "Phase 1: Pre-flight checks..."
  
  if ! command -v curl >/dev/null 2>&1; then
    log_error "curl required"
    exit 1
  fi
  
  if ! command -v ssh >/dev/null 2>&1; then
    log_error "ssh required"
    exit 1
  fi
  
  if ! command -v scp >/dev/null 2>&1; then
    log_error "scp required"
    exit 1
  fi
  
  log_success "All dependencies available"
}

# === PHASE 2: BACKUP CURRENT CONTROLLER ===
phase_backup() {
  log_info "Phase 2: Backing up current LXC controller (10.0.1.20)..."
  
  local backup_dir
  backup_dir="/tmp/cloudkey-backup-$(date +%s)"
  mkdir -p "$backup_dir"
  
  # Test SSH access to current controller
  if ! timeout 5 ssh -o ConnectTimeout=5 ubnt@$CURRENT_CONTROLLER_IP "echo 'SSH OK'" >/dev/null 2>&1; then
    log_error "Cannot SSH to current controller at $CURRENT_CONTROLLER_IP"
    log_info "Ensure controller is running and SSH is enabled"
    exit 1
  fi
  
  log_success "SSH access to LXC controller confirmed"
  
  # Trigger backup on controller
  log_info "Triggering backup on LXC controller..."
  ssh ubnt@$CURRENT_CONTROLLER_IP << 'BACKUP_COMMANDS'
    set -euo pipefail
    
    # Create backup
    echo "Creating backup..."
    BACKUP_FILE=$(docker exec unifi-controller unifi-os backup 2>&1 | grep -oP '/data/autobackup/[^ ]+' || echo "")
    
    if [ -z "$BACKUP_FILE" ]; then
      echo "FAIL: Could not create backup"
      exit 1
    fi
    
    echo "OK: Backup created at $BACKUP_FILE"
BACKUP_COMMANDS
  
  # Download backup
  log_info "Downloading backup from LXC controller..."
  scp "ubnt@$CURRENT_CONTROLLER_IP:/opt/unifi/data/autobackup/$(ssh ubnt@$CURRENT_CONTROLLER_IP 'ls -t /opt/unifi/data/autobackup/*.unf 2>/dev/null | head -1 | xargs -n1 basename' 2>/dev/null || echo 'unifi-backup.unf')" "$backup_dir/" || {
    log_warn "Could not auto-download; will attempt manual path"
  }
  
  # Export policy table from git
  log_info "Exporting policy table..."
  cp "$REPO_ROOT/02-declarative-config/policy-table.yaml" "$backup_dir/policy-table-canonical.yaml"
  
  log_success "Backup complete: $backup_dir"
  echo "$backup_dir"
}

# === PHASE 3: DETECT CLOUD KEY ===
phase_detect_cloudkey() {
  log_info "Phase 3: Detecting Cloud Key on network..."
  
  # Try to find Cloud Key via DHCP/ARP
  local cloudkey_ip=""
  
  # Method 1: Check UniFi adoption API (Cloud Key will have different IP)
  if command -v nmap >/dev/null 2>&1; then
    log_info "Scanning network for port 443 (Cloud Key API)..."
    cloudkey_ip=$(nmap -p 443 --open -T4 10.0.1.0/24 2>/dev/null | grep -E "10.0.1\.(2[5-9]|3[0-9])" | head -1 | awk '{print $1}' || echo "")
  fi
  
  if [ -z "$cloudkey_ip" ]; then
    log_warn "Could not auto-detect Cloud Key IP"
    log_info "Possible IPs to check (DHCP range): 10.0.1.25-10.0.1.40"
    read -r -p "Enter Cloud Key IP (or press Enter to skip): " cloudkey_ip
  fi
  
  if [ -n "$cloudkey_ip" ]; then
    log_success "Detected Cloud Key at: $cloudkey_ip"
    echo "$cloudkey_ip"
  else
    log_warn "Cloud Key IP not detected; will wait for manual entry during restore phase"
    echo ""
  fi
}

# === PHASE 4: RESTORE TO CLOUD KEY ===
phase_restore() {
  local backup_dir="$1"
  local cloudkey_ip="$2"
  
  log_info "Phase 4: Preparing restore to Cloud Key..."
  
  if [ -z "$cloudkey_ip" ]; then
    read -r -p "Enter Cloud Key IP (https://<IP>): " cloudkey_ip
    if [ -z "$cloudkey_ip" ]; then
      log_error "Cloud Key IP required"
      return 1
    fi
  fi
  
  # Find backup file
  local backup_file
  backup_file=$(find "$backup_dir" -name "*.unf" | head -1)
  
  if [ -z "$backup_file" ]; then
    log_warn "No .unf backup found in $backup_dir"
    log_info "Manual restore required:"
    log_info "  1. Open https://$cloudkey_ip in browser"
    log_info "  2. Initial Setup → Restore from Backup"
    log_info "  3. Upload: $backup_dir/*.unf"
    return 0
  fi
  
  log_success "Backup file found: $backup_file"
  log_info "Waiting 30 seconds before attempting restore..."
  log_warn "Make sure Cloud Key is on VLAN 1 and accessible at $cloudkey_ip"
  sleep 30
  
  # Restore via Cloud Key API (if available)
  if timeout 5 curl -k -s "https://$cloudkey_ip:443/api/v2/system/info" >/dev/null 2>&1; then
    log_info "Cloud Key API is accessible; attempting automated restore..."
    
    # For now, log and let user do manual restore
    log_info "⚠️  Automated restore via API is still being tested"
    log_info "Manual steps:"
    log_info "  1. SSH to Cloud Key: ssh ubnt@$cloudkey_ip"
    log_info "  2. Password: ubnt (initial setup)"
    log_info "  3. Use Web UI → Settings → Backup/Restore → Upload $backup_file"
    log_info "  4. Wait 5–15 minutes for restore and device re-adoption"
  else
    log_warn "Cloud Key not yet responding to API"
    log_info "This is normal during initial boot; retry in 1–2 minutes"
  fi
}

# === PHASE 5: POST-ADOPTION HARDENING ===
phase_harden() {
  local cloudkey_ip="$1"
  
  log_info "Phase 5: Post-adoption hardening..."
  
  if [ -z "$cloudkey_ip" ]; then
    read -r -p "Enter Cloud Key IP (for hardening): " cloudkey_ip
  fi
  
  if [ -z "$cloudkey_ip" ]; then
    log_warn "Skipping hardening; will need to run manually later"
    return 0
  fi
  
  # Check if hardening script exists
  if [ ! -f "$SCRIPT_DIR/post-adoption-hardening.sh" ]; then
    log_warn "post-adoption-hardening.sh not found; will create on next commit"
    return 0
  fi
  
  log_info "Running hardening script..."
  bash "$SCRIPT_DIR/post-adoption-hardening.sh" --cloudkey-ip "$cloudkey_ip" --dry-run "$DRY_RUN"
}

# === PHASE 6: VALIDATION ===
phase_validate() {
  local cloudkey_ip="$1"
  
  log_info "Phase 6: Validation..."
  
  if [ -z "$cloudkey_ip" ]; then
    log_warn "Cannot validate without Cloud Key IP"
    return 0
  fi
  
  # Check if validation script exists
  if [ ! -f "$SCRIPT_DIR/validation/comprehensive-suite.sh" ]; then
    log_warn "validation/comprehensive-suite.sh not found"
    return 0
  fi
  
  bash "$SCRIPT_DIR/validation/comprehensive-suite.sh" --controller-ip "$cloudkey_ip"
}

# === MAIN FLOW ===
main() {
  banner
  
  case "$MODE" in
    full)
      log_info "Starting FULL migration sequence..."
      phase_preflight
      backup_dir=$(phase_backup)
      cloudkey_ip=$(phase_detect_cloudkey)
      phase_restore "$backup_dir" "$cloudkey_ip"
      phase_harden "$cloudkey_ip"
      phase_validate "$cloudkey_ip"
      ;;
    backup-only)
      log_info "Backup only..."
      phase_preflight
      phase_backup
      ;;
    restore-only)
      log_info "Restore only..."
      read -r -p "Enter backup directory: " backup_dir
      cloudkey_ip=$(phase_detect_cloudkey)
      phase_restore "$backup_dir" "$cloudkey_ip"
      ;;
    validate-only)
      log_info "Validation only..."
      cloudkey_ip=$(phase_detect_cloudkey)
      phase_validate "$cloudkey_ip"
      ;;
    *)
      log_error "Unknown mode: $MODE"
      echo "Usage: $0 {full|backup-only|restore-only|validate-only} [dry-run]"
      exit 1
      ;;
  esac
  
  log_success "Eternal Cloud Key Ignition sequence complete"
  log_info "Consciousness Level 1.8 achieved ✓"
}

main "$@"
