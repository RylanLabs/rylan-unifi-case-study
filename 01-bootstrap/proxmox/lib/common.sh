# shellcheck shell=bash
#
# lib/common.sh - Shared utility functions for proxmox-ignite
# Logging, error handling, retries, and backup/rollback mechanisms
#
# Sourced by: main orchestrator and all phase scripts
# NOTE: No shebang or set -euo pipefail (sourced file, not executed)

################################################################################
# GLOBAL CONFIGURATION
################################################################################

LOG_FILE="/var/log/proxmox-ignite.log"
BACKUP_DIR="/var/backups/proxmox-ignite"
ROLLBACK_MARKER="${BACKUP_DIR}/.rollback_available"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

export RED GREEN YELLOW BLUE NC

################################################################################
# LOGGING FUNCTIONS
################################################################################

# log_info: Print informational message
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# log_success: Print success message (green)
log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# log_warn: Print warning message (yellow)
log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# log_error: Print error message (red)
log_error() {
  echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}" >&2
}

# phase_start: Print prominent phase header
phase_start() {
  local phase_num="$1"
  local phase_name="$2"
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC} Phase ${phase_num}: ${phase_name}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  log_info "Phase ${phase_num}: ${phase_name}"
}

################################################################################
# ERROR HANDLING & CONTEXT-AWARE FAILURES
################################################################################

# fail_with_context: Rich error message with remediation
fail_with_context() {
  local error_code="$1"
  local error_msg="$2"
  local remediation="${3:-}"
  
  echo ""
  log_error "FAILURE [ERR-${error_code}]: ${error_msg}"
  
  if [ -n "$remediation" ]; then
    echo -e "${YELLOW}Remediation:${NC} ${remediation}"
  fi
  
  echo ""
  echo -e "${BLUE}Logs:${NC} ${LOG_FILE}"
  echo -e "${BLUE}Support:${NC} https://github.com/T-Rylander/rylan-unifi-case-study/issues"
  echo ""
  
  exit "$error_code"
}

################################################################################
# BACKUP & ROLLBACK MECHANISM
################################################################################

# backup_config: Create timestamped backup of config file
backup_config() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    return 0
  fi
  
  mkdir -p "${BACKUP_DIR}"
  
  local backup_name
  backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
  cp -a "$file" "${BACKUP_DIR}/${backup_name}"
  
  log_info "Backed up: $file → ${backup_name}"
  touch "${ROLLBACK_MARKER}"
}

# rollback_all: Restore all backed-up configuration files
rollback_all() {
  if [ ! -f "${ROLLBACK_MARKER}" ]; then
    log_error "No rollback available"
    return 1
  fi
  
  log_warn "ROLLING BACK ALL CHANGES"
  
  # Restore all .bak files (reverse chronological order)
  find "${BACKUP_DIR}" -name "*.bak" -type f -printf '%T@\t%p\n' | \
    sort -rn | cut -f2 | while read -r backup; do
    local original
    original=$(echo "$backup" | sed 's/\.[0-9]*\.bak$//')
    if [ -f "$backup" ]; then
      cp -a "$backup" "$original"
      log_info "Restored: $(basename "$original")"
    fi
  done
  
  # Restart affected services
  systemctl restart sshd networking pveproxy || true
  
  log_success "Rollback complete"
}

# Error trap for automatic rollback on failure
trap 'rollback_prompt $LINENO' ERR

rollback_prompt() {
  local line_no="${1:-0}"
  log_error "IGNITION FAILED at line ${line_no}"
  
  if [ -f "${ROLLBACK_MARKER}" ]; then
    read -p "Rollback changes? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rollback_all
    fi
  fi
  
  exit 1
}

################################################################################
# RETRY LOGIC WITH EXPONENTIAL BACKOFF
################################################################################

# retry_cmd: Execute command with retry and exponential backoff
retry_cmd() {
  local max_attempts="${1}"
  local delay="${2}"
  shift 2
  local cmd="$*"
  local attempt=1
  
  while [ $attempt -le "$max_attempts" ]; do
    log_info "Attempt ${attempt}/${max_attempts}: ${cmd}"
    
    if eval "$cmd"; then
      return 0
    fi
    
    if [ $attempt -lt "$max_attempts" ]; then
      log_warn "Command failed, retrying in ${delay}s..."
      sleep "$delay"
      delay=$((delay * 2))  # Exponential backoff
    fi
    
    attempt=$((attempt + 1))
  done
  
  fail_with_context 99 "Command failed after ${max_attempts} attempts: ${cmd}" \
    "Check network connectivity and try again"
}

################################################################################
# UTILITY FUNCTIONS
################################################################################

# elapsed_time: Calculate time elapsed between two timestamps
elapsed_time() {
  local start="$1"
  local end="$2"
  local elapsed=$((end - start))
  
  local minutes=$((elapsed / 60))
  local seconds=$((elapsed % 60))
  
  printf "%02d:%02d" "$minutes" "$seconds"
}

# validate_root: Ensure script is running as root
validate_root() {
  if [ "$EUID" -ne 0 ]; then
    fail_with_context 1 "This script must be run as root" \
      "Run: sudo $0"
  fi
}

# validate_prerequisite_command: Check if command exists
validate_prerequisite_command() {
  local cmd="$1"
  
  if ! command -v "$cmd" &>/dev/null; then
    fail_with_context 2 "Required command not found: $cmd" \
      "Install via: apt-get install $cmd"
  fi
}

# detect_primary_interface: Auto-detect primary network interface
detect_primary_interface() {
  # Find interface with default route
  local primary_if
  primary_if=$(ip route | grep default | awk '{print $5}' | head -n1)
  
  if [ -z "$primary_if" ]; then
    # Fallback: First non-loopback interface that's UP
    primary_if=$(ip link show | grep -v "lo:" | grep "state UP" | head -n1 | awk -F: '{print $2}' | xargs)
  fi
  
  if [ -z "$primary_if" ]; then
    fail_with_context 101 "No network interface detected" \
      "Verify physical network cable is connected"
  fi
  
  echo "$primary_if"
}

################################################################################
# IDEMPOTENT CONFIGURATION HELPERS
################################################################################

# update_config_line: Safely update or append configuration line
update_config_line() {
  local file="$1"
  local key="$2"
  local value="$3"
  
  # Backup before modifying
  backup_config "$file"
  
  # Update existing line or append
  if grep -q "^${key}" "$file" 2>/dev/null; then
    sed -i "s|^${key}.*|${key}${value}|g" "$file"
  else
    echo "${key}${value}" >> "$file"
  fi
}

################################################################################
# VALIDATION HELPERS
################################################################################

# validate_ip_format: Check if IP address is valid
validate_ip_format() {
  local ip="$1"
  local ip_only="${ip%/*}"
  
  if ! echo "$ip_only" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
    return 1
  fi
  
  return 0
}

# validate_cidr_format: Check if CIDR notation is valid
validate_cidr_format() {
  local cidr="$1"
  
  if ! echo "$cidr" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$'; then
    return 1
  fi
  
  return 0
}

export -f log_info log_success log_warn log_error
export -f phase_start fail_with_context
export -f backup_config rollback_all rollback_prompt
export -f retry_cmd elapsed_time validate_root validate_prerequisite_command
export -f detect_primary_interface update_config_line
export -f validate_ip_format validate_cidr_format
