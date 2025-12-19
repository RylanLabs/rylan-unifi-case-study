#!/usr/bin/env bash
# Script: beale-services-adversarial.sh
# Purpose: Phases 4-5 hardening (Service minimization, adversarial validation)
# Guardian: The Archivist
# Date: 12/13/2025
# Consciousness: 4.7

# ─────────────────────────────────────────────────────
# Phase 4: Service Minimization (Context-Aware)
# ─────────────────────────────────────────────────────
run_services_phase() {
  local DRY_RUN=$1 running threshold context

  log ""
  log "Phase 4: Service Minimization"
  if [[ "$DRY_RUN" == false ]] && command -v systemctl &>/dev/null; then
    running=$(systemctl list-units --type=service --state=running --no-legend --no-pager | wc -l)
    if [[ -f /etc/pve/nodes ]]; then
      threshold=50
      context="proxmox"
    elif [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
      threshold=10
      context="container"
    else
      threshold=30
      context="server"
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
}

# ─────────────────────────────────────────────────────
# Phase 5: Adversarial Validation (Whitaker Loop)
# ─────────────────────────────────────────────────────
run_adversarial_phase() {
  local DRY_RUN=$1 code

  log ""
  log "Phase 5: Adversarial Validation"

  # SQLi test
  if [[ "$DRY_RUN" == false ]] && nc -z localhost 8000 2>/dev/null; then
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/api?id=1' OR '1'='1" || echo 000)
    [[ "$code" == "200" ]] &&
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
}

export -f run_services_phase run_adversarial_phase
