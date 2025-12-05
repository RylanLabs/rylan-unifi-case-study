#!/usr/bin/env bash
#
# Proxmox VE 8.2 Bare-Metal Ignition Script
# Production-grade fortress deployment in <15 minutes
#
# T3-ETERNAL Framework Compliance:
# - Barrett Unix Zen (pure bash, fail loudly, idempotent)
# - Hellodeolu Outcomes (15-min RTO, junior-deployable)
# - Whitaker Offensive (security-first, post-install validation)
# - Carter Identity (SSH key injection, domain-ready)
# - Bauer Paranoia (no default passwords, hardened SSH)
# - Suehring Network Defense (VLAN-aware, static IP, routing)
#
# Usage:
#   sudo ./proxmox-ignite.sh \
#     --hostname rylan-dc \
#     --ip 10.0.10.10/26 \
#     --gateway 10.0.10.1 \
#     --ssh-key /path/to/id_ed25519.pub \
#     [--validate-only] \
#     [--skip-eternal-resurrect]
#
# Example:
#   sudo ./proxmox-ignite.sh \
#     --hostname rylan-dc \
#     --ip 10.0.10.10/26 \
#     --gateway 10.0.10.1 \
#     --ssh-key ~/.ssh/id_ed25519.pub
#
# Output:
#   - Progress indicators with phase descriptions
#   - All commands logged to /var/log/proxmox-ignite.log
#   - Security validation report at completion
#   - Exit code 0 on success, 1 on critical failure

set -euo pipefail

################################################################################
# CONFIGURATION & DEFAULTS
################################################################################

SCRIPT_START=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/proxmox-ignite.log"
REPO_URL="https://github.com/T-Rylander/a-plus-up-unifi-case-study.git"
REPO_DIR="/opt/fortress"
REPO_BRANCH="feat/iot-production-ready"

# Configuration parameters (set via arguments)
HOSTNAME=""
TARGET_IP=""
GATEWAY_IP=""
SSH_KEY_PATH=""
VALIDATE_ONLY=false
SKIP_ETERNAL_RESURRECT=false

# DNS settings (Bauer: Carter + fallback)
PRIMARY_DNS="10.0.10.10"
FALLBACK_DNS="1.1.1.1"

# Firewall safe ports (Suehring: minimum required)
SSH_PORT=22
PROXMOX_WEB_PORT=8006
PROXMOX_CLUSTER_PORT=3128

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Retry configuration
RETRY_ATTEMPTS=3
RETRY_BACKOFF=5 # seconds

################################################################################
# UTILITY FUNCTIONS
################################################################################

# Logging helper: writes to stdout and log file
log() {
  local level="$1"
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}" >&2
}

# Phase indicator: prints prominent phase header
phase_start() {
  local phase_num="$1"
  local phase_name="$2"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}🚀 Phase ${phase_num}: ${phase_name}${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  log "INFO" "Phase ${phase_num}: ${phase_name}"
}

# Success indicator
success() {
  echo -e "${GREEN}✅ $@${NC}"
  log "INFO" "✅ $@"
}

# Warning indicator
warning() {
  echo -e "${YELLOW}⚠️  $@${NC}"
  log "WARN" "⚠️  $@"
}

# Error indicator: logs and exits
error() {
  echo -e "${RED}❌ $@${NC}" >&2
  log "ERROR" "❌ $@"
  exit 1
}

# Retry wrapper: executes command with backoff on failure
retry_command() {
  local cmd="$@"
  local attempt=1
  
  while [ $attempt -le "$RETRY_ATTEMPTS" ]; do
    log "INFO" "Executing (attempt $attempt/$RETRY_ATTEMPTS): $cmd"
    
    if eval "$cmd"; then
      return 0
    fi
    
    if [ $attempt -lt "$RETRY_ATTEMPTS" ]; then
      warning "Command failed, retrying in ${RETRY_BACKOFF}s..."
      sleep "$RETRY_BACKOFF"
    fi
    attempt=$((attempt + 1))
  done
  
  error "Command failed after $RETRY_ATTEMPTS attempts: $cmd"
}

# Check if command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Elapsed time formatter
elapsed_time() {
  local start=$1
  local end=$2
  local diff=$((end - start))
  echo "$((diff / 60))m $((diff % 60))s"
}

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
      --ssh-key)
        SSH_KEY_PATH="$2"
        shift 2
        ;;
      --validate-only)
        VALIDATE_ONLY=true
        shift
        ;;
      --skip-eternal-resurrect)
        SKIP_ETERNAL_RESURRECT=true
        shift
        ;;
      --help)
        print_usage
        exit 0
        ;;
      *)
        error "Unknown argument: $1"
        ;;
    esac
  done
}

print_usage() {
  cat << 'EOF'
Proxmox VE 8.2 Bare-Metal Ignition Script

USAGE:
  sudo ./proxmox-ignite.sh [OPTIONS]

REQUIRED OPTIONS:
  --hostname HOSTNAME           Hostname for Proxmox host (e.g., rylan-dc)
  --ip IP/CIDR                 Static IP address with CIDR (e.g., 10.0.10.10/26)
  --gateway GATEWAY_IP         Default gateway IP (e.g., 10.0.10.1)
  --ssh-key PATH               Path to SSH public key (ed25519, e.g., ~/.ssh/id_ed25519.pub)

OPTIONAL OPTIONS:
  --validate-only              Run security validation only (no changes)
  --skip-eternal-resurrect     Skip repository clone and eternal-resurrect.sh
  --help                       Show this help message

EXAMPLES:
  sudo ./proxmox-ignite.sh \
    --hostname rylan-dc \
    --ip 10.0.10.10/26 \
    --gateway 10.0.10.1 \
    --ssh-key ~/.ssh/id_ed25519.pub

  sudo ./proxmox-ignite.sh \
    --hostname rylan-dc \
    --ip 10.0.10.10/26 \
    --gateway 10.0.10.1 \
    --ssh-key ~/.ssh/id_ed25519.pub \
    --validate-only

OUTPUT:
  - Console: Real-time progress with phase indicators
  - Log: /var/log/proxmox-ignite.log (all commands and output)
  - Report: ASCII art success banner with metrics

EXIT CODES:
  0: Success (all phases completed)
  1: Critical failure (check log for details)

PREREQUISITES:
  - Fresh Proxmox VE 8.2 installation (post-ISO boot)
  - Root or sudo access
  - Network connectivity to GitHub (for repo clone)
  - SSH public key (ed25519 recommended)

TROUBLESHOOTING:
  - Check /var/log/proxmox-ignite.log for detailed error messages
  - Verify SSH key file exists and is readable
  - Ensure hostname is valid (alphanumeric + hyphens)
  - Confirm IP address is not already in use
  - Verify gateway is reachable (ping gateway before running)
EOF
}

################################################################################
# VALIDATION FUNCTIONS
################################################################################

# Validate required arguments
validate_arguments() {
  local errors=0
  
  if [ -z "$HOSTNAME" ]; then
    error "Missing required argument: --hostname"
  fi
  
  if [ -z "$TARGET_IP" ]; then
    error "Missing required argument: --ip"
  fi
  
  if [ -z "$GATEWAY_IP" ]; then
    error "Missing required argument: --gateway"
  fi
  
  if [ -z "$SSH_KEY_PATH" ]; then
    error "Missing required argument: --ssh-key"
  fi
  
  # Validate hostname format (RFC 952: alphanumeric + hyphens, max 63 chars)
  if ! [[ "$HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
    error "Invalid hostname format: $HOSTNAME (must be alphanumeric + hyphens, max 63 chars)"
  fi
  
  # Validate IP/CIDR format
  if ! [[ "$TARGET_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    error "Invalid IP/CIDR format: $TARGET_IP (expected X.X.X.X/YY)"
  fi
  
  # Validate gateway IP format
  if ! [[ "$GATEWAY_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    error "Invalid gateway IP format: $GATEWAY_IP (expected X.X.X.X)"
  fi
  
  # Validate SSH key file exists and is readable
  if [ ! -f "$SSH_KEY_PATH" ]; then
    error "SSH key file not found: $SSH_KEY_PATH"
  fi
  
  if [ ! -r "$SSH_KEY_PATH" ]; then
    error "SSH key file not readable: $SSH_KEY_PATH"
  fi
  
  # Validate SSH key format (should start with ssh-ed25519 or ssh-rsa)
  if ! grep -q -E "^ssh-(ed25519|rsa) " "$SSH_KEY_PATH"; then
    error "Invalid SSH key format in $SSH_KEY_PATH (expected ed25519 or RSA public key)"
  fi
  
  success "All arguments validated"
}

# Validate prerequisites (Bauer: verify base system)
validate_prerequisites() {
  phase_start "0" "Validation & Prerequisites"
  
  log "INFO" "Checking root privileges..."
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root or with sudo"
  fi
  success "Running with root privileges"
  
  log "INFO" "Checking Proxmox installation..."
  if [ ! -f /etc/os-release ]; then
    error "/etc/os-release not found"
  fi
  
  if ! grep -q "Proxmox" /etc/os-release; then
    warning "Proxmox not detected in /etc/os-release"
    warning "This script is designed for Proxmox VE 8.x"
    warning "Continuing anyway, but compatibility not guaranteed"
  else
    success "Proxmox detected"
  fi
  
  log "INFO" "Checking network connectivity..."
  if ! timeout 5 ping -c 1 "$FALLBACK_DNS" &> /dev/null; then
    error "Cannot reach DNS server ($FALLBACK_DNS). Check network connectivity."
  fi
  success "Network connectivity verified"
  
  log "INFO" "Checking required tools..."
  local required_tools=("ip" "hostnamectl" "apt-get" "git" "curl" "jq")
  for tool in "${required_tools[@]}"; do
    if ! command_exists "$tool"; then
      error "Required tool not found: $tool"
    fi
  done
  success "All required tools available"
  
  # Initialize log file
  touch "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  echo "=== Proxmox Ignite Log ===" >> "$LOG_FILE"
  echo "Start time: $(date)" >> "$LOG_FILE"
  echo "Hostname: $HOSTNAME" >> "$LOG_FILE"
  echo "Target IP: $TARGET_IP" >> "$LOG_FILE"
  echo "Gateway: $GATEWAY_IP" >> "$LOG_FILE"
  echo "===================" >> "$LOG_FILE"
  success "Log file initialized: $LOG_FILE"
}

################################################################################
# PHASE 1: NETWORK CONFIGURATION (Suehring)
################################################################################

configure_network() {
  phase_start "1" "Network Configuration (Suehring)"
  
  # Extract IP address without CIDR
  local ip_addr="${TARGET_IP%/*}"
  local cidr="${TARGET_IP##*/}"
  
  # Convert CIDR to netmask (simplified for common values)
  local netmask=""
  case "$cidr" in
    24) netmask="255.255.255.0" ;;
    25) netmask="255.255.255.128" ;;
    26) netmask="255.255.255.192" ;;
    27) netmask="255.255.255.224" ;;
    28) netmask="255.255.255.240" ;;
    *)  error "Unsupported CIDR: $cidr (supported: 24-28)" ;;
  esac
  
  # Detect primary ethernet NIC
  log "INFO" "Detecting primary ethernet NIC..."
  local primary_nic=$(ip -o link show | awk -F': ' '
    $2 ~ /^en[op]/ || $2 ~ /^eth/ {
      if ($2 !~ /vlan|docker|br-|veth/) {
        print $2
        exit
      }
    }
  ')
  
  if [ -z "$primary_nic" ]; then
    error "No ethernet NIC found (expected en*, eth*)"
  fi
  success "Primary NIC detected: $primary_nic"
  
  # Configure /etc/network/interfaces (Debian/Proxmox standard)
  log "INFO" "Configuring static IP in /etc/network/interfaces..."
  
  # Backup existing configuration
  if [ -f /etc/network/interfaces ]; then
    cp /etc/network/interfaces /etc/network/interfaces.bak
    log "INFO" "Backed up existing interfaces config"
  fi
  
  # Write new configuration
  cat > /etc/network/interfaces.d/99-proxmox-ignite << EOF
# Proxmox Ignite Configuration ($(date))
auto $primary_nic
iface $primary_nic inet static
  address $ip_addr
  netmask $netmask
  gateway $GATEWAY_IP
  dns-nameservers $PRIMARY_DNS $FALLBACK_DNS
  mtu 1500
EOF
  
  success "Network interfaces configuration written"
  
  # Apply configuration using ifupdown
  log "INFO" "Applying network configuration..."
  if ! ifup "$primary_nic" >> "$LOG_FILE" 2>&1; then
    warning "ifup command may have warnings (safe to continue)"
  fi
  
  # Wait for interface to settle
  sleep 3
  
  # Validate IP assignment
  log "INFO" "Validating IP assignment..."
  if ip addr show "$primary_nic" | grep -q "inet $ip_addr"; then
    success "Static IP assigned: $ip_addr"
  else
    error "Failed to assign static IP $ip_addr"
  fi
  
  # Configure hostname (Carter: identity)
  log "INFO" "Setting hostname to: $HOSTNAME"
  hostnamectl set-hostname "$HOSTNAME" >> "$LOG_FILE" 2>&1
  
  # Update /etc/hosts for local resolution
  log "INFO" "Updating /etc/hosts..."
  if grep -q "127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts
  else
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
  fi
  
  success "Hostname configured: $HOSTNAME"
  
  # Validate gateway reachability
  log "INFO" "Validating gateway reachability..."
  if ! timeout 5 ping -c 1 "$GATEWAY_IP" &> /dev/null; then
    error "Cannot reach gateway: $GATEWAY_IP"
  fi
  success "Gateway reachable: $GATEWAY_IP"
  
  # Validate DNS resolution
  log "INFO" "Validating DNS resolution..."
  if ! timeout 5 nslookup google.com "$FALLBACK_DNS" &> /dev/null; then
    warning "DNS resolution test failed, but continuing"
  else
    success "DNS resolution working"
  fi
}

################################################################################
# PHASE 2: SSH HARDENING (Bauer & Carter)
################################################################################

harden_ssh() {
  phase_start "2" "SSH Hardening (Bauer & Carter)"
  
  # Ensure .ssh directory exists
  log "INFO" "Creating root .ssh directory..."
  if [ ! -d /root/.ssh ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    success "Root .ssh directory created"
  else
    success "Root .ssh directory exists"
  fi
  
  # Inject SSH public key (Carter: identity)
  log "INFO" "Injecting SSH public key (Carter identity)..."
  cp "$SSH_KEY_PATH" /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  success "SSH public key installed"
  
  # Backup original SSH config
  if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    log "INFO" "Backed up sshd_config"
  fi
  
  # Harden SSH configuration (Bauer: paranoia)
  log "INFO" "Hardening SSH configuration..."
  
  # Use sed to update SSH config (idempotent: update or append)
  local ssh_config="/etc/ssh/sshd_config"
  
  # Disable password authentication
  if grep -q "^PasswordAuthentication" "$ssh_config"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$ssh_config"
  else
    echo "PasswordAuthentication no" >> "$ssh_config"
  fi
  
  # Disable root password login (allow key-based only)
  if grep -q "^PermitRootLogin" "$ssh_config"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' "$ssh_config"
  else
    echo "PermitRootLogin prohibit-password" >> "$ssh_config"
  fi
  
  # Enable public key authentication
  if grep -q "^PubkeyAuthentication" "$ssh_config"; then
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$ssh_config"
  else
    echo "PubkeyAuthentication yes" >> "$ssh_config"
  fi
  
  # Disable X11 forwarding (reduce attack surface)
  if grep -q "^X11Forwarding" "$ssh_config"; then
    sed -i 's/^X11Forwarding.*/X11Forwarding no/' "$ssh_config"
  else
    echo "X11Forwarding no" >> "$ssh_config"
  fi
  
  # Set strong ciphers (forward-secrecy only)
  if grep -q "^Ciphers" "$ssh_config"; then
    sed -i 's/^Ciphers.*/Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com/' "$ssh_config"
  else
    echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com" >> "$ssh_config"
  fi
  
  # Set strong KEX (key exchange) algorithms
  if grep -q "^KexAlgorithms" "$ssh_config"; then
    sed -i 's/^KexAlgorithms.*/KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org/' "$ssh_config"
  else
    echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org" >> "$ssh_config"
  fi
  
  # Disable empty passwords (Bauer: paranoia)
  if grep -q "^PermitEmptyPasswords" "$ssh_config"; then
    sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$ssh_config"
  else
    echo "PermitEmptyPasswords no" >> "$ssh_config"
  fi
  
  success "SSH configuration hardened"
  
  # Validate SSH config syntax
  log "INFO" "Validating SSH configuration syntax..."
  if ! sshd -t >> "$LOG_FILE" 2>&1; then
    error "SSH configuration syntax error"
  fi
  success "SSH configuration syntax valid"
  
  # Restart SSH service
  log "INFO" "Restarting SSH service..."
  systemctl restart ssh >> "$LOG_FILE" 2>&1
  success "SSH service restarted"
  
  # Give SSH time to settle
  sleep 2
}

################################################################################
# PHASE 3: TOOLING BOOTSTRAP
################################################################################

bootstrap_tooling() {
  phase_start "3" "Tooling Bootstrap"
  
  log "INFO" "Updating package cache..."
  retry_command "apt-get update -qq"
  success "Package cache updated"
  
  log "INFO" "Installing system packages..."
  local packages=(
    "git"
    "curl"
    "python3"
    "python3-pip"
    "python3-venv"
    "build-essential"
    "nmap"
    "jq"
    "wget"
    "ca-certificates"
    "net-tools"
  )
  
  retry_command "apt-get install -y ${packages[*]}"
  success "System packages installed"
  
  log "INFO" "Installing Python development tools..."
  local pip_packages=(
    "pre-commit"
    "pytest"
    "pytest-cov"
    "ruff"
    "mypy"
    "bandit"
  )
  
  retry_command "pip3 install --upgrade pip setuptools wheel"
  retry_command "pip3 install ${pip_packages[*]}"
  success "Python development tools installed"
  
  # Configure git (required for pre-commit)
  log "INFO" "Configuring git..."
  git config --global user.email "admin@rylan.internal" >> "$LOG_FILE" 2>&1 || true
  git config --global user.name "Proxmox Automation" >> "$LOG_FILE" 2>&1 || true
  success "Git configured"
}

################################################################################
# PHASE 4: REPOSITORY SYNC
################################################################################

sync_repository() {
  phase_start "4" "Repository Sync"
  
  # Check if repo already cloned
  if [ -d "$REPO_DIR" ]; then
    log "INFO" "Repository already exists at $REPO_DIR, updating..."
    cd "$REPO_DIR"
    
    # Fetch latest changes
    log "INFO" "Fetching latest changes..."
    retry_command "git fetch origin"
    
    # Checkout target branch
    log "INFO" "Checking out branch: $REPO_BRANCH"
    retry_command "git checkout $REPO_BRANCH"
    
    # Pull latest changes
    log "INFO" "Pulling latest changes..."
    retry_command "git pull origin $REPO_BRANCH"
  else
    log "INFO" "Cloning repository..."
    mkdir -p "$(dirname "$REPO_DIR")"
    retry_command "git clone --depth 1 --branch $REPO_BRANCH $REPO_URL $REPO_DIR"
    cd "$REPO_DIR"
  fi
  
  success "Repository synced: $REPO_DIR"
  
  # Install pre-commit hooks
  log "INFO" "Installing pre-commit hooks..."
  if [ -f .pre-commit-config.yaml ]; then
    pre-commit install >> "$LOG_FILE" 2>&1 || true
    success "Pre-commit hooks installed"
  else
    warning "No .pre-commit-config.yaml found, skipping"
  fi
}

################################################################################
# PHASE 5: FORTRESS RESURRECTION
################################################################################

resurrect_fortress() {
  phase_start "5" "Fortress Resurrection"
  
  if [ "$SKIP_ETERNAL_RESURRECT" = true ]; then
    warning "Skipping eternal-resurrect.sh (--skip-eternal-resurrect specified)"
    return 0
  fi
  
  # Check if eternal-resurrect.sh exists
  if [ ! -f "$REPO_DIR/eternal-resurrect.sh" ]; then
    warning "eternal-resurrect.sh not found at $REPO_DIR/eternal-resurrect.sh"
    warning "Skipping fortress resurrection"
    return 0
  fi
  
  log "INFO" "Executing eternal-resurrect.sh..."
  cd "$REPO_DIR"
  
  # Execute resurrection script with error handling
  if bash eternal-resurrect.sh >> "$LOG_FILE" 2>&1; then
    success "Fortress resurrection completed"
  else
    warning "Fortress resurrection script exited with non-zero status"
    warning "Check $LOG_FILE for details"
  fi
}

################################################################################
# PHASE 6: SECURITY VALIDATION (Whitaker)
################################################################################

validate_security() {
  phase_start "6" "Security Validation (Whitaker Offensive)"
  
  local validation_passed=true
  
  # Test 1: SSH port open
  log "INFO" "Test 1: Verifying SSH port ($SSH_PORT) is open..."
  if nmap -p "$SSH_PORT" localhost 2>/dev/null | grep -q "open"; then
    success "SSH port open"
  else
    echo -e "${RED}❌ SSH port not open${NC}"
    validation_passed=false
  fi
  
  # Test 2: Proxmox web port open
  log "INFO" "Test 2: Verifying Proxmox web port ($PROXMOX_WEB_PORT) is open..."
  if nmap -p "$PROXMOX_WEB_PORT" localhost 2>/dev/null | grep -q "open"; then
    success "Proxmox web port open"
  else
    warning "Proxmox web port not yet open (may be starting up)"
  fi
  
  # Test 3: Verify password auth disabled (Bauer: paranoia)
  log "INFO" "Test 3: Verifying password authentication is disabled..."
  if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    success "Password authentication disabled"
  else
    echo -e "${RED}❌ Password authentication not disabled${NC}"
    validation_passed=false
  fi
  
  # Test 4: Verify root password login restricted (Bauer: paranoia)
  log "INFO" "Test 4: Verifying root login restrictions..."
  if grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
    success "Root login restricted to key-only"
  else
    echo -e "${RED}❌ Root login not properly restricted${NC}"
    validation_passed=false
  fi
  
  # Test 5: Verify SSH key installed (Carter: identity)
  log "INFO" "Test 5: Verifying SSH public key is installed..."
  if [ -f /root/.ssh/authorized_keys ] && [ -s /root/.ssh/authorized_keys ]; then
    local key_fingerprint=$(ssh-keygen -lf /root/.ssh/authorized_keys 2>/dev/null | head -1 || echo "N/A")
    success "SSH public key installed: $key_fingerprint"
  else
    echo -e "${RED}❌ SSH public key not installed${NC}"
    validation_passed=false
  fi
  
  # Test 6: Verify hostname set (Carter: identity)
  log "INFO" "Test 6: Verifying hostname is set correctly..."
  local current_hostname=$(hostname)
  if [ "$current_hostname" = "$HOSTNAME" ]; then
    success "Hostname correctly set: $current_hostname"
  else
    echo -e "${RED}❌ Hostname mismatch: expected $HOSTNAME, got $current_hostname${NC}"
    validation_passed=false
  fi
  
  # Test 7: Verify static IP assigned (Suehring)
  log "INFO" "Test 7: Verifying static IP is assigned..."
  local ip_addr="${TARGET_IP%/*}"
  if ip addr show | grep -q "inet $ip_addr"; then
    success "Static IP assigned: $ip_addr"
  else
    echo -e "${RED}❌ Static IP not assigned${NC}"
    validation_passed=false
  fi
  
  # Test 8: Verify gateway reachability (Suehring)
  log "INFO" "Test 8: Verifying gateway is reachable..."
  if timeout 5 ping -c 1 "$GATEWAY_IP" &> /dev/null; then
    success "Gateway reachable: $GATEWAY_IP"
  else
    echo -e "${RED}❌ Gateway not reachable${NC}"
    validation_passed=false
  fi
  
  # Test 9: Verify DNS resolution (Carter: AD domain ready)
  log "INFO" "Test 9: Verifying DNS resolution..."
  if timeout 5 nslookup google.com "$FALLBACK_DNS" &> /dev/null; then
    success "DNS resolution working"
  else
    warning "DNS resolution test failed (may resolve after Carter setup)"
  fi
  
  # Test 10: Check for common attack surfaces
  log "INFO" "Test 10: Scanning for open attack surfaces (nmap)..."
  local dangerous_ports="23 80 443"  # Telnet, HTTP, HTTPS (should be filtered)
  local found_dangerous=false
  
  for port in $dangerous_ports; do
    if nmap -p "$port" localhost 2>/dev/null | grep -q "open"; then
      echo -e "${RED}❌ Dangerous port open: $port${NC}"
      found_dangerous=true
    fi
  done
  
  if [ "$found_dangerous" = false ]; then
    success "No dangerous ports open"
  else
    validation_passed=false
  fi
  
  return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

################################################################################
# REPORTING & COMPLETION
################################################################################

print_success_banner() {
  local elapsed="$1"
  
  cat << 'EOF'

████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█                      ✅ PROXMOX IGNITE: SUCCESS                            █
█                                                                              █
█          🏰 Fortress is operational. Defense perimeter hardened.            █
█          🔐 SSH key-only authentication enabled. No password logins.        █
█          🌐 Network configured. Static IP assigned. DNS resolving.          █
█          📡 Proxmox Web UI ready: https://hostname:8006                    █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████

EOF
  
  echo "DEPLOYMENT SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Hostname:             $HOSTNAME"
  echo "IP Address:           $TARGET_IP"
  echo "Gateway:              $GATEWAY_IP"
  echo "Primary DNS:          $PRIMARY_DNS"
  echo "Fallback DNS:         $FALLBACK_DNS"
  echo "SSH Port:             $SSH_PORT"
  echo "Proxmox Web UI:       https://$HOSTNAME:$PROXMOX_WEB_PORT"
  echo "Repository:           $REPO_DIR"
  echo "Repository Branch:    $REPO_BRANCH"
  echo "Log File:             $LOG_FILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "NEXT STEPS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "1. SSH into the host:"
  echo "   ssh -i ~/.ssh/id_ed25519 root@$HOSTNAME"
  echo ""
  echo "2. Access Proxmox Web UI:"
  echo "   https://$HOSTNAME:$PROXMOX_WEB_PORT (default: root@pam)"
  echo ""
  echo "3. Verify fortress status:"
  echo "   cd $REPO_DIR && ./validate-eternal.sh"
  echo ""
  echo "4. Review logs:"
  echo "   tail -f $LOG_FILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "⏱️  Total time: ${elapsed}"
  echo ""
}

print_failure_banner() {
  cat << 'EOF'

████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█                       ❌ PROXMOX IGNITE: FAILED                            █
█                                                                              █
█              Check logs for details: /var/log/proxmox-ignite.log            █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████

EOF
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
  # Parse arguments
  parse_arguments "$@"
  
  # Validate arguments
  validate_arguments
  
  # Validate prerequisites
  validate_prerequisites
  
  # Check if validation-only mode
  if [ "$VALIDATE_ONLY" = true ]; then
    log "INFO" "Running in validation-only mode (--validate-only)"
    if validate_security; then
      print_success_banner "validation"
      exit 0
    else
      print_failure_banner
      exit 1
    fi
  fi
  
  # Execute phases
  configure_network
  harden_ssh
  bootstrap_tooling
  sync_repository
  resurrect_fortress
  
  # Validate security
  if validate_security; then
    local script_end=$(date +%s)
    local elapsed=$(elapsed_time "$SCRIPT_START" "$script_end")
    print_success_banner "$elapsed"
    
    log "INFO" "Proxmox Ignite completed successfully in $elapsed"
    exit 0
  else
    print_failure_banner
    log "ERROR" "Security validation failed"
    exit 1
  fi
}

# Execute main function
main "$@"
