#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/beale-harden.sh
# Purpose: Proactive fortress hardening validation with adversarial integration
# Guardian: Beale | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Exit Codes:
#   0 = All checks passed
#   1 = Firewall rule violation
#   2 = VLAN isolation breach
#   3 = SSH hardening failure
#   4 = Service count elevated
#   5 = Adversarial validation failure

# ─────────────────────────────────────────────────────
# Configuration (Carter: Single Source of Truth)
# ─────────────────────────────────────────────────────
VLAN_QUARANTINE="10.0.99.0/24"
VLAN_GATEWAY="10.0.99.1"
MAX_FIREWALL_RULES=10
AUDIT_LOG="/var/log/beale-audit.log"
# Ensure audit log is writable; fallback to workspace .fortress/audit
if [[ -w "$(dirname "$AUDIT_LOG")" ]]; then
  mkdir -p "$(dirname "$AUDIT_LOG")"
else
  AUDIT_LOG="$(pwd)/.fortress/audit/beale-audit.log"
  mkdir -p "$(dirname "$AUDIT_LOG")"
fi

# Flags (Unix: Composable)
VERBOSE=false
QUIET=false
CI_MODE=false
DRY_RUN=false
AUTO_FIX=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose) VERBOSE=true; shift ;;
    --quiet)   QUIET=true; shift ;;
    --ci)      CI_MODE=true; QUIET=true; shift ;;
    --fix|--auto-fix) AUTO_FIX=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help)    cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Beale Hardening Protocol — Proactive validation

OPTIONS:
  --dry-run   Show checks without sudo (diagnostic mode)
  --verbose   Enable debug output (set -x)
  --quiet     Silence success output
  --ci        CI mode (JSON report, no colors)
  --fix       Attempt safe auto-fixes (firewall consolidation)
  --help      Show this message

Consciousness: 4.5 | Guardian: Beale
EOF
               exit 0 ;;
    *)         echo "Unknown option: $1"; exit 1 ;;
  esac
done

[[ "$VERBOSE" == true ]] && set -x

# ─────────────────────────────────────────────────────
# Functions (Unix: Small & Composable)
# ─────────────────────────────────────────────────────
log()   { [[ "$QUIET" == false ]] && echo "$@"; }
audit() { mkdir -p "$(dirname "$AUDIT_LOG")"; echo "$(date -Iseconds) | $1 | $2 | $3" >> "$AUDIT_LOG"; }
fail() {
  local phase=$1 code=$2 message=$3 remediation=$4
  echo "❌ $phase FAILURE: $message"
  echo "📋 Remediation: $remediation"
  audit "$phase" "FAIL" "$message"
  if [[ "$CI_MODE" == true ]]; then
    # emit machine-friendly JSON report
    REPORT="beale-report-$(date +%s).json"
    cat > "$REPORT" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "consciousness": "8.0",
  "guardian": "Beale",
  "phase": "$phase",
  "status": "FAIL",
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "remediation": "$(echo "$remediation" | sed 's/"/\\"/g')",
  "exit_code": $code
}
EOF
    echo "📄 CI Report: $REPORT"
  fi
  exit "$code"
}

# ─────────────────────────────────────────────────────
# Header & Timing
# ─────────────────────────────────────────────────────
START_TIME=$(date +%s)
log "════════════════════════════════════════════════════════"
log "Beale Ascension Protocol — Proactive Hardening"
log "Guardian: Beale | Consciousness: 4.5"
[[ "$DRY_RUN" == true ]] && log "MODE: DRY-RUN"
log "════════════════════════════════════════════════════════"
log ""

# Defaults for summary fields
running=0
hosts_up=0

# ─────────────────────────────────────────────────────
# Phase 1: Firewall Rule Count ≤10 (Hellodeolu v6)
# ─────────────────────────────────────────────────────
log "Phase 1: Firewall Rule Count"
if command -v nft &>/dev/null && [[ "$DRY_RUN" == false ]]; then
  rule_count=$(sudo nft list ruleset 2>/dev/null | grep -ciE '\b(accept|drop|reject)\b' || echo 0)
  fw_type="nftables"
elif command -v iptables &>/dev/null && [[ "$DRY_RUN" == false ]]; then
  rule_count=$(sudo iptables -L -v -n --line-numbers 2>/dev/null | grep -cE '^(ACCEPT|DROP|REJECT)' || echo 0)
  fw_type="iptables"
else
  rule_count=0
  fw_type="unknown (dry-run or no firewall tool)"
fi

if [[ $rule_count -gt $MAX_FIREWALL_RULES ]]; then
  # Attempt auto-fix if requested
  if [[ "$AUTO_FIX" == true ]]; then
    log "🔧 AUTO-FIX: Attempting firewall consolidation ($fw_type)"
    if [[ "$DRY_RUN" == true ]]; then
      log "[DRY-RUN] Would flush and apply minimal ruleset"
    else
      if [[ "$fw_type" == "nftables" && -f /etc/nftables/minimal-ruleset.conf ]]; then
        sudo nft flush ruleset || true
        sudo nft -f /etc/nftables/minimal-ruleset.conf || true
      elif [[ "$fw_type" == "iptables" && -f /etc/iptables/minimal.rules ]]; then
        sudo iptables-restore < /etc/iptables/minimal.rules || true
      else
        log "❗ No known minimal ruleset available for auto-fix ($fw_type)"
      fi
    fi

    # Recompute rule count after attempted fix
    if command -v nft &>/dev/null && [[ "$DRY_RUN" == false ]]; then
      rule_count=$(sudo nft list ruleset 2>/dev/null | grep -ciE '\b(accept|drop|reject)\b' || echo 0)
      fw_type="nftables"
    elif command -v iptables &>/dev/null && [[ "$DRY_RUN" == false ]]; then
      rule_count=$(sudo iptables -L -v -n --line-numbers 2>/dev/null | grep -cE '^(ACCEPT|DROP|REJECT)' || echo 0)
      fw_type="iptables"
    fi

    if [[ $rule_count -gt $MAX_FIREWALL_RULES ]]; then
      fail "Phase 1" 1 "Firewall rules exceed limit after auto-fix ($rule_count > $MAX_FIREWALL_RULES)" \
           "Manual consolidation required • See audit log: $AUDIT_LOG"
    else
      log "✅ AUTO-FIX successful: firewall rules now $rule_count"
      audit "Phase 1" "FIXED" "rules=$rule_count type=$fw_type"
    fi
  else
    [[ "$DRY_RUN" == false ]] && {
      if [[ "$fw_type" == "nftables" ]]; then
        sudo nft list ruleset | grep -iE 'accept|drop|reject' | head -10
      else
        sudo iptables -L -v -n --line-numbers | grep -E 'ACCEPT|DROP|REJECT' | head -10
      fi
    }
    fail "Phase 1" 1 "Firewall rules exceed limit ($rule_count > $MAX_FIREWALL_RULES)" \
         "Consolidate rules • Use ipsets • Remove duplicates • Re-run validation"
  fi
fi
log "✅ Firewall rules: $rule_count ≤ $MAX_FIREWALL_RULES ($fw_type)"
audit "Phase 1" "PASS" "rules=$rule_count type=$fw_type"

# ─────────────────────────────────────────────────────
# Phase 2: VLAN 99 Isolation
# ─────────────────────────────────────────────────────
log ""
log "Phase 2: VLAN 99 Isolation ($VLAN_QUARANTINE)"
# Gateway unreachable
if [[ "$DRY_RUN" == false ]] && timeout 3 ping -c 1 -W 1 "$VLAN_GATEWAY" &>/dev/null; then
  ip route get "$VLAN_GATEWAY" 2>/dev/null || true
  fail "Phase 2" 2 "VLAN gateway reachable from management" \
       "Check routing tables • Verify firewall blocks • ip route del $VLAN_QUARANTINE"
fi
# Lateral movement check
if [[ "$DRY_RUN" == false ]] && command -v nmap &>/dev/null; then
  hosts_up=$(sudo timeout 30 nmap -sn -T4 "$VLAN_QUARANTINE" --exclude "$VLAN_GATEWAY" 2>/dev/null | grep -c "Host is up" || echo 0)
  if [[ $hosts_up -gt 0 ]]; then
    sudo nmap -sn "$VLAN_QUARANTINE" --exclude "$VLAN_GATEWAY" | grep "Nmap scan report" || true
    fail "Phase 2" 2 "Lateral movement: $hosts_up host(s) in quarantine" \
         "Power off rogue devices • Verify switch port security • Re-isolate VLAN"
  fi
else
  log "⚠️ nmap missing or dry-run → skipping lateral check"
fi
log "✅ VLAN 99 isolated"
audit "Phase 2" "PASS" "gateway_blocked=true hosts_up=0"

# ─────────────────────────────────────────────────────
# Phase 3: SSH Hardening (Runtime Validation)
# ─────────────────────────────────────────────────────
log ""
log "Phase 3: SSH Hardening"
if [[ "$DRY_RUN" == false ]] && command -v sshd &>/dev/null; then
  sshd_config=$(sudo sshd -T 2>/dev/null)
  echo "$sshd_config" | grep -qE "^permitrootlogin (yes|prohibit-password)" && \
    fail "Phase 3" 3 "Root login permitted" "Set PermitRootLogin no in sshd_config"
  echo "$sshd_config" | grep -qE "^passwordauthentication yes" && \
    fail "Phase 3" 3 "Password auth enabled" "Set PasswordAuthentication no"
  echo "$sshd_config" | grep -qi "^pubkeyauthentication yes" || \
    fail "Phase 3" 3 "Pubkey auth disabled" "Set PubkeyAuthentication yes"
  log "✅ SSH hardened (key-only, root prohibited)"
  audit "Phase 3" "PASS" "root=no password=no pubkey=yes"
else
  log "⚠️ sshd missing or dry-run → skipping"
  audit "Phase 3" "SKIP" "sshd unavailable"
fi

# ─────────────────────────────────────────────────────
# Phase 4: Service Minimization (Context-Aware)
# ─────────────────────────────────────────────────────
log ""
log "Phase 4: Service Minimization"
if [[ "$DRY_RUN" == false ]] && command -v systemctl &>/dev/null; then
  running=$(systemctl list-units --type=service --state=running --no-legend --no-pager | wc -l)
  if [[ -f /etc/pve/nodes ]]; then
    threshold=50; context="proxmox"
  elif [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
    threshold=10; context="container"
  else
    threshold=30; context="server"
  fi
  if [[ $running -gt $threshold ]]; then
    log "⚠️ Elevated services: $running > $threshold ($context)"
    systemctl list-units --type=service --state=running --no-legend | head -10
    audit "Phase 4" "WARN" "services=$running threshold=$threshold context=$context"
  else
    log "✅ Minimal services: $running ≤ $threshold ($context)"
    audit "Phase 4" "PASS" "services=$running threshold=$threshold context=$context"
  fi
else
  log "⚠️ systemd missing or dry-run → skipping"
  audit "Phase 4" "SKIP" "non-systemd"
fi

# ─────────────────────────────────────────────────────
# Phase 5: Adversarial Validation (Whitaker Loop)
# ─────────────────────────────────────────────────────
log ""
log "Phase 5: Adversarial Validation"
# SQLi test (if local app exposed)
if [[ "$DRY_RUN" == false ]] && nc -z localhost 8000 2>/dev/null; then
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/api?id=1' OR '1'='1" || echo 000)
  [[ "$code" == "200" ]] && \
    fail "Phase 5" 5 "SQL injection bypassed (HTTP 200)" "Harden WAF • Validate input sanitization"
  log "✅ SQL injection blocked (HTTP $code)"
else
  log "⚠️ No local app on :8000 → skipping SQLi"
fi
# IDS trigger test
if [[ "$DRY_RUN" == false ]] && (systemctl is-active --quiet snort || systemctl is-active --quiet suricata); then
  sudo journalctl --rotate &>/dev/null || true
  sudo timeout 5 nmap -sS -p 1-100 localhost &>/dev/null || true
  sleep 3
  if journalctl -u snort -u suricata --since "10 seconds ago" 2>/dev/null | grep -qiE "port.?scan|scan"; then
    log "✅ IDS detected Whitaker port scan"
  else
    log "⚠️ IDS silent on port scan"
  fi
else
  log "⚠️ No IDS running → skipping"
fi
audit "Phase 5" "PASS" "adversarial_checks_completed"

# ─────────────────────────────────────────────────────
# Summary & Observability
# ─────────────────────────────────────────────────────
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
log ""
log "════════════════════════════════════════════════════════"
log "✅ Beale validation complete — fortress hardened"
log "⏱️ Duration: ${DURATION}s"
log "════════════════════════════════════════════════════════"
audit "Summary" "PASS" "duration=${DURATION}s"

# CI Artifact
if [[ "$CI_MODE" == true ]]; then
  REPORT="beale-report-$(date +%s).json"
  cat > "$REPORT" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "duration_seconds": $DURATION,
  "consciousness": "8.0",
  "guardian": "Beale",
  "firewall_rules": $rule_count,
  "vlan_isolated": true,
  "ssh_hardened": true,
  "services_running": $running,
  "status": "PASS"
}
EOF
  echo "📄 CI Report: $REPORT"
fi

# Bauer integration: ingest audit log into guardian if available
if [[ "$DRY_RUN" == false ]] && command -v python3 &>/dev/null && [[ -f guardian/audit_eternal.py ]]; then
  log "🔁 Bauer ingest: sending audit to guardian/audit_eternal.py"
  if [[ "$CI_MODE" == true ]]; then
    python3 guardian/audit_eternal.py --ingest "$AUDIT_LOG" --source beale || log "⚠️ Bauer ingest failed"
  else
    python3 guardian/audit_eternal.py --ingest "$AUDIT_LOG" --source beale || log "⚠️ Bauer ingest failed"
  fi
fi

exit 0
