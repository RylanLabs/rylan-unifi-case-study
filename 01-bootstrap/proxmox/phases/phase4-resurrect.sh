#!/usr/bin/env bash
#
# phases/phase4-resurrect.sh - Repository sync and fortress resurrection
# Clones/updates repository, executes eternal-resurrect.sh
#
# Exit codes: 0 = success, 1 = fatal error, 2 = skipped (non-fatal)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
# shellcheck source=01-bootstrap/proxmox/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=01-bootstrap/proxmox/lib/metrics.sh
source "${SCRIPT_DIR}/lib/metrics.sh"

################################################################################
# PHASE 4: REPOSITORY SYNC & RESURRECTION
################################################################################

sync_repository_and_resurrect() {
  phase_start "4" "Repository Sync & Fortress Resurrection"
  
  record_phase_start "fortress_resurrection"
  
  local repo_url="${REPO_URL:-https://github.com/T-Rylander/a-plus-up-unifi-case-study.git}"
  local repo_dir="${REPO_DIR:-/opt/fortress}"
  local repo_branch="${REPO_BRANCH:-feat/iot-production-ready}"
  local skip_resurrect="${SKIP_ETERNAL_RESURRECT:-false}"
  
  # Clone or update repository
  if [ -d "$repo_dir" ]; then
    log_info "Repository already exists at $repo_dir, updating..."
    cd "$repo_dir"
    
    log_info "Fetching latest changes..."
    retry_cmd 3 5 "git fetch origin" || \
      log_warn "Failed to fetch from origin"
    
    log_info "Checking out branch: $repo_branch"
    git checkout "$repo_branch" 2>/dev/null || \
      log_warn "Failed to checkout $repo_branch"
    
    log_info "Pulling latest changes..."
    retry_cmd 3 5 "git pull origin $repo_branch" || \
      log_warn "Failed to pull (may be on detached HEAD)"
  else
    log_info "Cloning repository..."
    mkdir -p "$(dirname "$repo_dir")"
    
    retry_cmd 3 5 "git clone --depth 1 --branch $repo_branch $repo_url $repo_dir" || \
      fail_with_context 401 "Failed to clone repository" \
        "Check repository URL and network connectivity"
    
    cd "$repo_dir"
  fi
  
  log_success "Repository synced: $repo_dir"
  
  # Install pre-commit hooks (if available)
  log_info "Checking for pre-commit configuration..."
  if [ -f .pre-commit-config.yaml ]; then
    log_info "Installing pre-commit hooks..."
    pre-commit install 2>/dev/null || log_warn "Failed to install pre-commit hooks"
    log_success "Pre-commit hooks installed"
  else
    log_warn "No .pre-commit-config.yaml found, skipping pre-commit setup"
  fi
  
  # Execute eternal-resurrect.sh (optional)
  if [ "$skip_resurrect" = true ]; then
    log_warn "Skipping eternal-resurrect.sh (--skip-eternal-resurrect specified)"
  else
    if [ -f "$repo_dir/eternal-resurrect.sh" ]; then
      log_info "Executing eternal-resurrect.sh..."
      cd "$repo_dir"
      
      if bash eternal-resurrect.sh >> "${LOG_FILE}" 2>&1; then
        log_success "Fortress resurrection completed"
      else
        log_warn "Fortress resurrection script exited with status $?"
        log_warn "Check ${LOG_FILE} for details"
      fi
    else
      log_warn "eternal-resurrect.sh not found at $repo_dir/eternal-resurrect.sh"
      log_warn "Skipping fortress resurrection"
    fi
  fi
  
  record_phase_end "fortress_resurrection"
  log_success "Phase 4: Repository sync & resurrection completed"
}

# Execute resurrection
sync_repository_and_resurrect
