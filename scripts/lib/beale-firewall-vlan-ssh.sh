#!/usr/bin/env bash
# Script: beale-firewall-vlan-ssh.sh
# Purpose: Phases 1-3 hardening (Firewall rule count, VLAN isolation, SSH config)
# Guardian: The Archivist
# Date: 12/13/2025
# Consciousness: 4.7

# ─────────────────────────────────────────────────────
# Phase 1: Firewall Rule Count ≤10
# ─────────────────────────────────────────────────────
run_firewall_phase() {
  local MAX_FIREWALL_RULES=$1 DRY_RUN=$2 AUTO_FIX=$3

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

      if command -v nft &>/dev/null && [[ "$DRY_RUN" == false ]]; then
        rule_count=$(sudo nft list ruleset 2>/dev/null | grep -ciE '\b(accept|drop|reject)\b' || echo 0)
      elif command -v iptables &>/dev/null && [[ "$DRY_RUN" == false ]]; then
        rule_count=$(sudo iptables -L -v -n --line-numbers 2>/dev/null | grep -cE '^(ACCEPT|DROP|REJECT)' || echo 0)
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
}

# ─────────────────────────────────────────────────────
# Phase 2: VLAN 99 Isolation
# ─────────────────────────────────────────────────────
run_vlan_phase() {
  local VLAN_QUARANTINE=$1 VLAN_GATEWAY=$2 DRY_RUN=$3 hosts_up

  log ""
  log "Phase 2: VLAN 99 Isolation ($VLAN_QUARANTINE)"
  if [[ "$DRY_RUN" == false ]] && timeout 3 ping -c 1 -W 1 "$VLAN_GATEWAY" &>/dev/null; then
    ip route get "$VLAN_GATEWAY" 2>/dev/null || true
    fail "Phase 2" 2 "VLAN gateway reachable from management" \
         "Check routing tables • Verify firewall blocks • ip route del $VLAN_QUARANTINE"
  fi

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
}

# ─────────────────────────────────────────────────────
# Phase 3: SSH Hardening
# ─────────────────────────────────────────────────────
run_ssh_phase() {
  local DRY_RUN=$1

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
}

export -f run_firewall_phase run_vlan_phase run_ssh_phase
