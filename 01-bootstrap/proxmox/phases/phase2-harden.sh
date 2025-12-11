#!/usr/bin/env bash
#
# phases/phase2-harden.sh - SSH hardening and security configuration
# Key-only authentication, cipher configuration, firewall rules
#
# Exit codes: 0 = success, 1 = fatal error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
# shellcheck source=01-bootstrap/proxmox/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=01-bootstrap/proxmox/lib/metrics.sh
source "${SCRIPT_DIR}/lib/metrics.sh"

################################################################################
# PHASE 2: SECURITY HARDENING
################################################################################

harden_ssh() {
  phase_start "2" "Security Hardening - SSH & Firewall"

  record_phase_start "security_hardening"

  local ssh_config="/etc/ssh/sshd_config"
  # shellcheck disable=SC2153  # SSH_KEY_SOURCE exported by orchestrator
  local ssh_key_source="${SSH_KEY_SOURCE}"

  # Backup SSH config
  backup_config "$ssh_config"

  log_info "Hardening SSH configuration..."

  # Disable password authentication (Bauer: paranoia)
  update_config_line "$ssh_config" "PasswordAuthentication " " no"

  # Disable root password login (key-only)
  update_config_line "$ssh_config" "PermitRootLogin " " prohibit-password"

  # Enable public key authentication
  update_config_line "$ssh_config" "PubkeyAuthentication " " yes"

  # Disable X11 forwarding (reduce attack surface)
  update_config_line "$ssh_config" "X11Forwarding " " no"

  # Disable empty passwords
  update_config_line "$ssh_config" "PermitEmptyPasswords " " no"

  # Set strong ciphers (ChaCha20, AES-GCM forward-secrecy only)
  update_config_line "$ssh_config" "Ciphers " " chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com"

  # Set strong KEX algorithms (Curve25519 forward-secrecy)
  update_config_line "$ssh_config" "KexAlgorithms " " curve25519-sha256,curve25519-sha256@libssh.org"

  log_success "SSH configuration hardened"

  # Validate SSH config syntax
  log_info "Validating SSH configuration syntax..."
  if ! sshd -t 2>/tmp/sshd-test.log; then
    fail_with_context 201 "SSH configuration syntax error" \
      "Check /tmp/sshd-test.log for details"
  fi
  log_success "SSH configuration syntax valid"

  # Install SSH key (multi-source support)
  log_info "Installing SSH key from: ${ssh_key_source}"
  fetch_and_install_ssh_key "$ssh_key_source"

  # Restart SSH service
  log_info "Restarting SSH service..."
  systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null ||
    fail_with_context 202 "Failed to restart SSH service" \
      "Check SSH configuration: sshd -t"

  log_success "SSH service restarted"
  sleep 2

  record_phase_end "security_hardening"
  log_success "Phase 2: Security hardening completed successfully"
}

# Fetch SSH key from various sources
fetch_and_install_ssh_key() {
  local key_source="$1"
  local ssh_key=""

  case "$key_source" in
    github:*)
      local github_user="${key_source#github:}"
      log_info "Fetching SSH key from GitHub user: ${github_user}"
      ssh_key=$(curl -sSL "https://github.com/${github_user}.keys" 2>/dev/null)

      if [ -z "$ssh_key" ] || echo "$ssh_key" | grep -q "Not Found"; then
        fail_with_context 203 "No SSH keys found for GitHub user: ${github_user}" \
          "Verify username is correct: github.com/${github_user}"
      fi
      ;;

    file:*)
      local key_file="${key_source#file:}"
      log_info "Loading SSH key from file: ${key_file}"

      if [ ! -f "$key_file" ]; then
        fail_with_context 204 "SSH key file not found: ${key_file}" \
          "Create key: ssh-keygen -t ed25519 -f ${key_file}"
      fi
      ssh_key=$(cat "$key_file")
      ;;

    inline:*)
      ssh_key="${key_source#inline:}"
      log_info "Using inline SSH key"
      ;;

    *)
      fail_with_context 205 "Invalid SSH key source format: ${key_source}" \
        "Supported: github:user, file:/path, inline:key"
      ;;
  esac

  # Validate key format
  if ! echo "$ssh_key" | grep -qE '^(ssh-ed25519|ecdsa-sha2-|ssh-rsa)'; then
    fail_with_context 206 "Invalid SSH key format" \
      "Key must start with ssh-ed25519, ecdsa-sha2-, or ssh-rsa"
  fi

  # Install SSH key
  mkdir -p /root/.ssh
  echo "$ssh_key" >/root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys

  local key_info
  key_info=$(echo "$ssh_key" | awk '{print $1, substr($2,1,20)"..."}')
  log_success "SSH key installed: $key_info"
}

# Execute SSH hardening
harden_ssh
