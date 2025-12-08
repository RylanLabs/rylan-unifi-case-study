#!/usr/bin/env bash
#
# phases/phase1-network.sh - Network configuration
# Static IP assignment, DNS setup, netplan configuration
#
# Exit codes: 0 = success, 1 = fatal error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
# shellcheck source=01-bootstrap/proxmox/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=01-bootstrap/proxmox/lib/metrics.sh
source "${SCRIPT_DIR}/lib/metrics.sh"

################################################################################
# PHASE 1: NETWORK CONFIGURATION
################################################################################

configure_network() {
  phase_start "1" "Network Configuration"
  
  record_phase_start "network_configuration"
  
  # Parse parameters from environment (set by orchestrator)
  # shellcheck disable=SC2153  # TARGET_IP exported by orchestrator
  local target_ip="${TARGET_IP}"
  # shellcheck disable=SC2153  # GATEWAY_IP exported by orchestrator
  local gateway_ip="${GATEWAY_IP}"
  local primary_dns="${PRIMARY_DNS:-10.0.10.10}"
  local fallback_dns="${FALLBACK_DNS:-1.1.1.1}"
  
  log_info "Configuring network: ${target_ip} via ${gateway_ip}"
  
  # Detect primary interface
  local primary_if
  primary_if=$(detect_primary_interface)
  log_info "Primary interface detected: ${primary_if}"
  
  # Backup existing netplan config
  backup_config /etc/netplan/01-netcfg.yaml
  
  # Create netplan configuration
  log_info "Writing netplan configuration..."
  cat > /etc/netplan/01-proxmox-ignite.yaml <<EOF
network:
  version: 2
  ethernets:
    ${primary_if}:
      dhcp4: no
      addresses: [${target_ip}]
      routes:
        - to: default
          via: ${gateway_ip}
      nameservers:
        addresses: [${primary_dns}, ${fallback_dns}]
      dhcp4-overrides:
        use-dns: false
EOF
  
  log_success "Netplan configuration created"
  
  # Apply netplan
  log_info "Applying netplan configuration..."
  if ! netplan apply 2>/tmp/netplan-error.log; then
    local error_msg
    error_msg=$(cat /tmp/netplan-error.log 2>/dev/null || echo "Unknown error")
    fail_with_context 102 "Netplan configuration failed" \
      "Check IP/CIDR format (e.g., 10.0.10.10/26). Error: $error_msg"
  fi
  
  log_success "Netplan applied"
  
  # Wait for network to settle
  sleep 2
  
  # Validate gateway reachability
  log_info "Validating gateway reachability: ${gateway_ip}"
  retry_cmd 3 5 "ping -c 1 -W 5 ${gateway_ip}" || \
    fail_with_context 103 "Cannot reach gateway: ${gateway_ip}" \
      "Verify gateway IP is correct and network is operational"
  
  log_success "Gateway reachable"
  
  # Validate internet connectivity
  log_info "Validating internet connectivity..."
  retry_cmd 3 5 "ping -c 1 -W 5 1.1.1.1" || \
    fail_with_context 104 "No internet connectivity" \
      "Check firewall rules and upstream routing"
  
  log_success "Internet connectivity verified"
  
  record_phase_end "network_configuration"
  log_success "Phase 1: Network configuration completed successfully"
}

# Execute network configuration
configure_network
