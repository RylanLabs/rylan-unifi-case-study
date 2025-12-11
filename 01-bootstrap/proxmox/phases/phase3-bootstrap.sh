#!/usr/bin/env bash
#
# phases/phase3-bootstrap.sh - Tooling and package installation
# System utilities, Python development tools, Git configuration
#
# Exit codes: 0 = success, 1 = fatal error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
# shellcheck source=01-bootstrap/proxmox/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=01-bootstrap/proxmox/lib/metrics.sh
source "${SCRIPT_DIR}/lib/metrics.sh"

################################################################################
# PHASE 3: TOOLING BOOTSTRAP
################################################################################

bootstrap_tooling() {
  phase_start "3" "Tooling Bootstrap"

  record_phase_start "tooling_installation"

  log_info "Updating package cache..."
  retry_cmd 3 5 "apt-get update -qq" ||
    fail_with_context 301 "Failed to update package cache" \
      "Check internet connectivity"

  log_success "Package cache updated"

  # Install system packages
  log_info "Installing system packages..."
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

  retry_cmd 3 5 "apt-get install -y ${packages[*]}" ||
    fail_with_context 302 "Failed to install system packages" \
      "Check internet connectivity and package availability"

  log_success "System packages installed"

  # Install Python development tools
  log_info "Installing Python development tools..."
  local pip_packages=(
    "pre-commit"
    "pytest"
    "pytest-cov"
    "ruff"
    "mypy"
    "bandit"
  )

  retry_cmd 3 5 "pip3 install --upgrade pip setuptools wheel" ||
    log_warn "Failed to upgrade pip (continuing)"

  retry_cmd 3 5 "pip3 install ${pip_packages[*]}" ||
    log_warn "Failed to install some Python tools (continuing)"

  log_success "Python development tools installed"

  # Configure Git (required for pre-commit and repo operations)
  log_info "Configuring git..."
  git config --global user.email "admin@rylan.internal" || true
  git config --global user.name "Proxmox Automation" || true

  log_success "Git configured"

  record_phase_end "tooling_installation"
  log_success "Phase 3: Tooling bootstrap completed successfully"
}

# Execute tooling bootstrap
bootstrap_tooling
