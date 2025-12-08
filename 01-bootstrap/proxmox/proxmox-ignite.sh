#!/usr/bin/env bash
#
# Proxmox VE 8.2 Bare-Metal Ignition - Main Orchestrator
# Modular, <150 LOC orchestrator that sequences 5 phase modules
# T3-ETERNAL compliant: Unix Philosophyatomic phases, Hellodeolu RTO, Whitaker offensive
#
# Usage:
#   sudo ./proxmox-ignite.sh \
#     --hostname rylan-dc \
#     --ip 10.0.10.10/26 \
#     --gateway 10.0.10.1 \
#     --ssh-key-source github:T-Rylander \
#     [--validate-only] [--dry-run]

set -euo pipefail

################################################################################
# CONFIGURATION & SETUP
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/proxmox-ignite.log"

# Source shared libraries
# shellcheck source=01-bootstrap/proxmox/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=01-bootstrap/proxmox/lib/metrics.sh
source "${SCRIPT_DIR}/lib/metrics.sh"
# shellcheck source=01-bootstrap/proxmox/lib/security.sh
source "${SCRIPT_DIR}/lib/security.sh"

# Global environment variables (passed to phases)
export SCRIPT_DIR LOG_FILE
export HOSTNAME TARGET_IP GATEWAY_IP SSH_KEY_SOURCE
export PRIMARY_DNS FALLBACK_DNS
export REPO_URL REPO_DIR REPO_BRANCH
export SKIP_ETERNAL_RESURRECT DRY_RUN VALIDATE_ONLY

# Defaults
HOSTNAME=""
TARGET_IP=""
GATEWAY_IP=""
SSH_KEY_SOURCE="github:T-Rylander"
PRIMARY_DNS="10.0.10.10"
FALLBACK_DNS="1.1.1.1"
REPO_URL="https://github.com/T-Rylander/a-plus-up-unifi-case-study.git"
REPO_DIR="/opt/fortress"
REPO_BRANCH="feat/iot-production-ready"
SKIP_ETERNAL_RESURRECT=false
DRY_RUN=false
VALIDATE_ONLY=false

################################################################################
# ARGUMENT PARSING
################################################################################

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --hostname)
        HOSTNAME="$2"
        shift 2
        ;;
      --ip)
        TARGET_IP="$2"
        shift 2
        ;;
      --gateway)
        GATEWAY_IP="$2"
        shift 2
        ;;
      --ssh-key-source)
        SSH_KEY_SOURCE="$2"
        shift 2
        ;;
      --dns-primary)
        PRIMARY_DNS="$2"
        shift 2
        ;;
      --dns-secondary)
        FALLBACK_DNS="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --validate-only)
        VALIDATE_ONLY=true
        shift
        ;;
      --skip-eternal-resurrect)
        SKIP_ETERNAL_RESURRECT=true
        shift
        ;;
      *)
        log_error "Unknown argument: $1"
        print_usage
        exit 1
        ;;
    esac
  done
}

print_usage() {
  cat << 'EOF'
Usage: proxmox-ignite.sh [OPTIONS]

Required Options:
  --hostname HOSTNAME           System hostname (e.g., rylan-dc)
  --ip IP/CIDR                  IP address with CIDR (e.g., 10.0.10.10/26)
  --gateway GATEWAY             Default gateway IP (e.g., 10.0.10.1)

Optional Options:
  --ssh-key-source SOURCE       SSH key source (default: github:T-Rylander)
                                Formats: github:user, file:/path, inline:key
  --dns-primary DNS             Primary DNS server (default: 10.0.10.10)
  --dns-secondary DNS           Secondary DNS server (default: 1.1.1.1)
  --dry-run                     Preview without making changes
  --validate-only               Pre-flight checks only
  --skip-eternal-resurrect      Skip fortress resurrection script

Example:
  sudo ./proxmox-ignite.sh \
    --hostname rylan-dc \
    --ip 10.0.10.10/26 \
    --gateway 10.0.10.1 \
    --ssh-key-source github:T-Rylander
EOF
}

################################################################################
# VALIDATION
################################################################################

validate_arguments() {
  if [ -z "$HOSTNAME" ] || [ -z "$TARGET_IP" ] || [ -z "$GATEWAY_IP" ]; then
    log_error "Missing required arguments"
    print_usage
    exit 1
  fi
  
  if ! validate_cidr_format "$TARGET_IP"; then
    fail_with_context 1 "Invalid IP/CIDR format: $TARGET_IP" \
      "Expected format: 10.0.10.10/26"
  fi
  
  if ! validate_ip_format "$GATEWAY_IP"; then
    fail_with_context 1 "Invalid gateway IP format: $GATEWAY_IP" \
      "Expected format: 10.0.10.1"
  fi
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
  # Parse and validate arguments
  parse_arguments "$@"
  validate_arguments
  
  # Initialize logging
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "Proxmox Ignite started: $(date)" > "$LOG_FILE"
  
  log_info "=== PROXMOX IGNITION SEQUENCE INITIATED ==="
  log_info "Hostname: $HOSTNAME"
  log_info "IP/CIDR: $TARGET_IP"
  log_info "Gateway: $GATEWAY_IP"
  log_info "SSH Key Source: $SSH_KEY_SOURCE"
  
  # Execute phases sequentially
  "${SCRIPT_DIR}/phases/phase0-validate.sh" || \
    fail_with_context 1 "Phase 0 validation failed" "Review logs"
  
  hostnamectl set-hostname "$HOSTNAME" || log_warn "Failed to set hostname"
  
  "${SCRIPT_DIR}/phases/phase1-network.sh" || \
    fail_with_context 1 "Phase 1 network configuration failed" "Review logs"
  
  "${SCRIPT_DIR}/phases/phase2-harden.sh" || \
    fail_with_context 1 "Phase 2 security hardening failed" "Review logs"
  
  "${SCRIPT_DIR}/phases/phase3-bootstrap.sh" || \
    fail_with_context 1 "Phase 3 tooling installation failed" "Review logs"
  
  "${SCRIPT_DIR}/phases/phase4-resurrect.sh" || \
    log_warn "Phase 4 had issues (non-fatal, continuing)"
  
  # Collect system metrics
  collect_system_metrics
  
  # Run Whitaker offensive security validation
  if run_whitaker_offensive_suite "$HOSTNAME" "$TARGET_IP" "$GATEWAY_IP" \
       "$FALLBACK_DNS"; then
    finalize_metrics
    log_success "=== PROXMOX IGNITION COMPLETE ==="
    log_success "Fortress operational. RTO compliance achieved."
    exit 0
  else
    finalize_metrics
    log_error "=== PROXMOX IGNITION COMPLETED WITH SECURITY WARNINGS ==="
    exit 1
  fi
}

# Execute main
main "$@"
