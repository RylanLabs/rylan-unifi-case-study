#!/usr/bin/env bash
#
# Quick Start Script: Proxmox Ignite Deployment
#
# This script automates the entire proxmox-ignite.sh deployment
# with sensible defaults for a quick lab environment setup.
#
# Usage:
#   sudo bash ./proxmox-ignite-quickstart.sh
#
# This will:
# 1. Prompt for essential parameters (hostname, IP, SSH key)
# 2. Validate prerequisites
# 3. Execute proxmox-ignite.sh with your settings
# 4. Display results and next steps

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IGNITE_SCRIPT="${SCRIPT_DIR}/proxmox-ignite.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

################################################################################
# HELPER FUNCTIONS
################################################################################

prompt_text() {
  local prompt="$1"
  local default="$2"
  local input

  if [ -n "$default" ]; then
    read -r -p "$(echo -e "${CYAN}${prompt}${NC}") [${default}]: " input
    echo "${input:-$default}"
  else
    read -r -p "$(echo -e "${CYAN}${prompt}${NC}"): " input
    echo "$input"
  fi
}

print_banner() {
  cat <<'EOF'

████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█             🚀 Proxmox VE 8.2 Ignite — Quick Start Deployment              █
█                                                                              █
█              Automated bare-metal fortress in <15 minutes                   █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████

EOF
}

print_configuration() {
  local hostname="$1"
  local ip="$2"
  local gateway="$3"
  local ssh_key="$4"

  cat <<EOF

${BOLD}Deployment Configuration:${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Hostname:      $hostname
  IP Address:    $ip
  Gateway:       $gateway
  SSH Key:       $ssh_key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

################################################################################
# MAIN
################################################################################

main() {
  print_banner

  # Check prerequisites
  echo -e "${CYAN}📋 Checking prerequisites...${NC}"

  if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
  fi
  echo "✅ Running as root"

  if [ ! -f "$IGNITE_SCRIPT" ]; then
    echo "❌ proxmox-ignite.sh not found at: $IGNITE_SCRIPT"
    exit 1
  fi
  echo "✅ proxmox-ignite.sh found"

  # Collect user input
  echo ""
  echo -e "${CYAN}${BOLD}Enter Proxmox Host Configuration:${NC}"
  echo ""

  local hostname
  hostname=$(prompt_text "Hostname" "rylan-dc")

  local ip
  ip=$(prompt_text "IP Address (CIDR)" "10.0.10.10/26")

  local gateway
  gateway=$(prompt_text "Gateway IP" "10.0.10.1")

  # SSH key handling
  echo ""
  echo -e "${CYAN}SSH Key Configuration:${NC}"
  local default_key="$HOME/.ssh/id_ed25519.pub"

  local ssh_key
  if [ -f "$default_key" ]; then
    ssh_key=$(prompt_text "SSH Public Key Path" "$default_key")
  else
    echo "No SSH key found at $default_key"
    ssh_key=$(prompt_text "SSH Public Key Path" "")
  fi

  if [ -z "$ssh_key" ]; then
    echo "❌ SSH key path required"
    exit 1
  fi

  if [ ! -f "$ssh_key" ]; then
    echo "❌ SSH key not found: $ssh_key"
    exit 1
  fi

  # Review configuration
  echo ""
  print_configuration "$hostname" "$ip" "$gateway" "$ssh_key"

  # Confirm before proceeding
  read -r -p "$(echo -e "${YELLOW}Proceed with deployment? [y/N]: ${NC}")" confirm

  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Deployment cancelled"
    exit 0
  fi

  # Execute ignition script
  echo ""
  echo -e "${CYAN}🔥 Starting Proxmox Ignition...${NC}"
  echo ""

  if bash "$IGNITE_SCRIPT" \
    --hostname "$hostname" \
    --ip "$ip" \
    --gateway "$gateway" \
    --ssh-key "$ssh_key"; then

    echo ""
    echo -e "${GREEN}${BOLD}✅ Deployment Successful!${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. SSH into the host:"
    echo "   ${BOLD}ssh -i ~/.ssh/id_ed25519 root@$hostname${NC}"
    echo ""
    echo "2. Access Proxmox Web UI:"
    echo "   ${BOLD}https://$hostname:8006${NC}"
    echo ""
    echo "3. Verify fortress status:"
    echo "   ${BOLD}cd /opt/fortress && ./validate-eternal.sh${NC}"
    echo ""
  else
    echo ""
    echo -e "${RED}${BOLD}❌ Deployment Failed!${NC}"
    echo "Check /var/log/proxmox-ignite.log for details"
    exit 1
  fi
}

main "$@"
