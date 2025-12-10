#!/usr/bin/env bash
# runbooks/ministry-detection/rylan-beale-eternal-one-shot.sh
# Beale Ministry: Detection is the First Line of Defense (Snort + Wazuh)
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

log() { printf '%b\n' "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${SCRIPT_NAME}: $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

readonly SECRETS_FILE="${SCRIPT_DIR}/../../.secrets/wazuh-api-key"
[[ -f "${SECRETS_FILE}" ]] || die "Vault missing: .secrets/wazuh-api-key"
WAZUH_API_KEY="$(<"${SECRETS_FILE}")"
export WAZUH_API_KEY
readonly WAZUH_API_KEY

readonly WAZUH_MANAGER="10.0.20.50"
readonly SNORT_INTERFACE="ens18"
readonly ALERT_WEBHOOK="${ALERT_WEBHOOK:-}"

preflight_checks() {
  [[ $EUID -eq 0 ]] || die "Must run as root"
  command -v snort >/dev/null || die "Snort not installed"
  command -v wazuh-agent >/dev/null || die "Wazuh agent not installed"
}

configure_snort() {
  log "Configuring Snort IDS on ${SNORT_INTERFACE}"
  [[ -f /etc/snort/snort.conf ]] || die "Snort config missing"
  cat > /etc/snort/rules/eternal.rules <<'EOF'
# Eternal Fortress IDS Rules — Beale Ministry
alert tcp any any -> $HOME_NET 22 (msg:"SSH brute force attempt"; flags:S; threshold:type both,track by_src,count 5,seconds 60; sid:1000001;)
alert tcp $HOME_NET any -> any any (msg:"Suspicious outbound connection from IoT VLAN"; sid:1000002;)
alert icmp any any -> $HOME_NET any (msg:"ICMP flood detected"; threshold:type both,track by_src,count 50,seconds 10; sid:1000003;)
EOF
  systemctl enable snort
  systemctl restart snort || die "Snort failed to start"
}

configure_wazuh_agent() {
  log "Configuring Wazuh agent → ${WAZUH_MANAGER}"
  /var/ossec/bin/agent-auth -m "${WAZUH_MANAGER}" -A "$(hostname)" || die "Wazuh registration failed"
  systemctl enable wazuh-agent
  systemctl restart wazuh-agent || die "Wazuh agent failed to start"
}

deploy_honeypot() {
  log "Deploying SSH honeypot on port 2222"
  if command -v cowrie >/dev/null 2>&1; then
    systemctl enable cowrie
    systemctl restart cowrie || log "WARN: Cowrie failed to start"
  else
    log "WARN: Cowrie not installed, skipping honeypot"
  fi
}

validate_detection() {
  systemctl is-active snort >/dev/null || die "Snort not running"
  /var/ossec/bin/agent_control -l | grep -q "$(hostname)" || die "Wazuh agent not connected"
}

main() {
  log "════════════════ Beale Ministry — Detection First ════════════════"
  preflight_checks
  configure_snort
  configure_wazuh_agent
  deploy_honeypot
  validate_detection
  log "✓ BEALE MINISTRY COMPLETE — IDS on ${SNORT_INTERFACE}, Wazuh ${WAZUH_MANAGER}"
  [[ -n "${ALERT_WEBHOOK}" ]] && log "Alert webhook configured: ${ALERT_WEBHOOK}"
}

main "$@"
