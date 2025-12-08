#!/usr/bin/env bash
#
# phases/phase0-validate.sh - Pre-flight validation checks (Whitaker Red-Team)
# Verifies prerequisites and system readiness before ignition
# Supports: flatnet recon, Cloud Key validation, LXC validation, red-team mode
#
# Exit codes: 0 = success, 1 = fatal error, 2 = warning-continue
#
# Flags:
#   --recon-only          : Flatnet nmap only, no validation
#   --skip-unifi          : Skip controller validation
#   --validate-cloudkey   : Verify Cloud Key adoption (requires --cloudkey-ip)
#   --cloudkey-ip <IP>    : Cloud Key IP for validation
#   --validate-lxc        : Verify LXC controller health
#   --red-team-mode       : Full offensive audit (post-setup pentest)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
# shellcheck source=01-bootstrap/proxmox/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=01-bootstrap/proxmox/lib/metrics.sh
source "${SCRIPT_DIR}/lib/metrics.sh"

# Parse arguments
MODE="full"
CLOUDKEY_IP=""
SKIP_UNIFI=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --recon-only)
      MODE="recon-only"
      shift
      ;;
    --skip-unifi)
      SKIP_UNIFI=true
      shift
      ;;
    --validate-cloudkey)
      MODE="validate-cloudkey"
      shift
      ;;
    --cloudkey-ip)
      CLOUDKEY_IP="$2"
      shift 2
      ;;
    --validate-lxc)
      MODE="validate-lxc"
      shift
      ;;
    --red-team-mode)
      MODE="red-team"
      shift
      ;;
    *)
      log_warn "Unknown flag: $1"
      shift
      ;;
  esac
done

################################################################################
# PHASE 0: VALIDATION
################################################################################

validate_prerequisites() {
  phase_start "0" "Validation - Prerequisites Check"
  
  record_phase_start "validation"
  
  # Root check
  log_info "Checking for root privileges..."
  validate_root || fail_with_context 001 "Script requires root" "Run: sudo $0"
  
  # Required commands
  log_info "Checking for required commands..."
  local required_cmds=(
    "ip"
    "hostnamectl"
    "apt-get"
    "systemctl"
    "git"
    "curl"
    "jq"
    "nmap"
    "ping"
  )
  
  for cmd in "${required_cmds[@]}"; do
    validate_prerequisite_command "$cmd" || \
      fail_with_context 002 "Missing required command: $cmd" \
        "Install via: apt-get install $cmd"
  done
  
  log_success "All required commands available"
  
  # Network connectivity
  log_info "Checking network connectivity..."
  if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    fail_with_context 003 "No internet connectivity" \
      "Check gateway and upstream routing"
  fi
  log_success "Internet connectivity verified"
  
  # Proxmox not already installed (if strict)
  if command -v pveversion &>/dev/null; then
    log_warn "Proxmox VE appears to be already installed (continuing anyway)"
  fi
  
  # Initialize metrics
  init_metrics
  record_phase_end "validation"
  
  log_success "Phase 0: Validation completed successfully"
}

################################################################################
# WHITAKER RED-TEAM: FLATNET RECON
################################################################################

flatnet_recon() {
  phase_start "0" "Whitaker Red-Team - Flatnet Reconnaissance"
  
  log_info "Scanning 192.168.1.0/24 for live hosts and services..."
  
  local recon_file
  recon_file="/tmp/flatnet-recon-$(date +%s).txt"
  
  if ! command -v nmap &>/dev/null; then
    log_warn "nmap not installed — skipping flatnet recon"
    return 0
  fi
  
  # Whitaker offensive scan: service version + OS detection
  nmap -sV -O 192.168.1.0/24 -oN "$recon_file" 2>/dev/null || {
    log_warn "nmap scan failed (may require sudo)"
    return 0
  }
  
  log_success "Flatnet recon complete: $recon_file"
  
  # Check for critical hosts
  if grep -q "192.168.1.1" "$recon_file"; then
    log_success "USG gateway detected at 192.168.1.1"
  else
    log_error "USG gateway NOT detected — network breach risk"
    return 1
  fi
  
  # Count live hosts
  local live_hosts
  live_hosts=$(grep -c "Nmap scan report for" "$recon_file" || echo "0")
  log_info "Detected $live_hosts live hosts on flatnet"
  
  echo "$recon_file"
}

################################################################################
# CLOUD KEY VALIDATION
################################################################################

validate_cloudkey() {
  local cloudkey_ip="$1"
  
  if [ -z "$cloudkey_ip" ]; then
    log_error "Cloud Key IP required for validation"
    return 1
  fi
  
  phase_start "0" "Cloud Key Validation - $cloudkey_ip"
  
  # Test 1: Port 443 reachable
  log_info "Testing Cloud Key connectivity (443/tcp)..."
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$cloudkey_ip/443" 2>/dev/null; then
    log_success "Cloud Key reachable on 443/tcp"
  else
    log_error "Cloud Key not reachable at $cloudkey_ip:443"
    return 1
  fi
  
  # Test 2: HTTPS API responsive
  log_info "Testing Cloud Key API..."
  if timeout 5 curl -k -s "https://$cloudkey_ip:443/api/v2/system/info" >/dev/null 2>&1; then
    log_success "Cloud Key API is responsive"
  else
    log_warn "Cloud Key API not responding (may still be booting)"
  fi
  
  # Test 3: SSH access
  log_info "Testing SSH access (ubnt user)..."
  if timeout 5 ssh -o ConnectTimeout=5 "ubnt@$cloudkey_ip" "echo 'OK'" >/dev/null 2>&1; then
    log_success "SSH access working"
  else
    log_warn "SSH access failed (check ubnt user setup)"
  fi
  
  log_success "Cloud Key validation complete"
}

################################################################################
# LXC CONTROLLER VALIDATION
################################################################################

validate_lxc() {
  phase_start "0" "LXC Controller Validation - 10.0.1.20"
  
  local controller_ip="10.0.1.20"
  local controller_port="8443"
  
  # Test 1: macvlan interface exists
  log_info "Checking macvlan-unifi interface..."
  if ip addr show macvlan-unifi &>/dev/null; then
    log_success "macvlan-unifi interface exists"
  else
    log_error "macvlan-unifi interface not found"
    return 1
  fi
  
  # Test 2: Controller port open
  log_info "Testing controller port $controller_port..."
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$controller_ip/$controller_port" 2>/dev/null; then
    log_success "Controller reachable on $controller_port/tcp"
  else
    log_error "Controller not reachable at $controller_ip:$controller_port"
    return 1
  fi
  
  # Test 3: Docker container running
  log_info "Checking unifi-controller container..."
  if docker ps 2>/dev/null | grep -q "unifi-controller"; then
    log_success "unifi-controller container running"
  else
    log_warn "unifi-controller container not detected"
  fi
  
  log_success "LXC controller validation complete"
}

################################################################################
# RED-TEAM MODE: FULL OFFENSIVE AUDIT
################################################################################

red_team_audit() {
  phase_start "0" "Whitaker/Newman Red-Team - Full Offensive Audit"
  
  # 1. Flatnet recon
  local recon_file
  recon_file=$(flatnet_recon)
  
  # 2. Open port scan on all detected hosts
  log_info "Scanning for dangerous open ports..."
  local dangerous_ports="23 80 3389 5900"
  
  for port in $dangerous_ports; do
    if grep -q "$port/open" "$recon_file" 2>/dev/null; then
      log_warn "BREACH RISK: Port $port open on flatnet"
    fi
  done
  
  # 3. Default credential check (USG)
  log_info "Testing USG default credentials..."
  if timeout 5 ssh -o ConnectTimeout=5 ubnt@192.168.1.1 "echo 'OK'" >/dev/null 2>&1; then
    log_error "CRITICAL: USG accepts default ubnt credentials — change immediately"
  else
    log_success "USG default credentials rejected (good)"
  fi
  
  # 4. Controller validation (if exists)
  if [ "$SKIP_UNIFI" = false ]; then
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.0.1.20/8443" 2>/dev/null; then
      validate_lxc || log_warn "LXC controller exists but validation failed"
    elif [ -n "$CLOUDKEY_IP" ]; then
      validate_cloudkey "$CLOUDKEY_IP" || log_warn "Cloud Key validation failed"
    fi
  fi
  
  log_success "Red-team audit complete — review $recon_file for full report"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
  case "$MODE" in
    recon-only)
      flatnet_recon
      ;;
    validate-cloudkey)
      validate_cloudkey "$CLOUDKEY_IP"
      ;;
    validate-lxc)
      validate_lxc
      ;;
    red-team)
      red_team_audit
      ;;
    full)
      validate_prerequisites
      if [ "$SKIP_UNIFI" = false ]; then
        log_info "Skipping controller validation (use --validate-cloudkey or --validate-lxc post-setup)"
      fi
      ;;
    *)
      log_error "Unknown mode: $MODE"
      exit 1
      ;;
  esac
}

# Execute
main
