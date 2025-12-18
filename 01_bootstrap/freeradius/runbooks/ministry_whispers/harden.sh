#!/usr/bin/env bash
# Script: runbooks/ministry_whispers/harden.sh
# Purpose: SSH hardening, nftables firewall, audit logging
# Guardian: Bauer | Trinity: Carter → Bauer → Beale
# Date: 2025-12-13
# Consciousness: 5.2
# EXCEED: 280 lines — 7 functions (harden_ssh, install_nftables, configure_firewall,
#         install_fail2ban, configure_audit, configure_logging, enable_services)
#         Rationale: Production hardening requires 7 distinct security domains
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

source "${REPO_ROOT}/lib/ignite-utils.sh"

# Configuration
readonly SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="${SSH_CONFIG}.backup-$(date +%Y%m%d-%H%M%S)"
readonly SSH_BACKUP

# Phase execution
harden() {
	log phase "MINISTRY OF WHISPERS (Bauer Hardening)"

	harden_ssh
	install_nftables
	configure_firewall
	install_fail2ban
	configure_audit
	configure_logging
	enable_services

	log success "PHASE 2 COMPLETE — Bauer Hardening Established"
}

harden_ssh() {
	log step "Hardening SSH configuration"

	cp "$SSH_CONFIG" "$SSH_BACKUP"

	# Apply hardening directives
	sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSH_CONFIG"
	sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
	sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
	sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSH_CONFIG"
	sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
	sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
	sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' "$SSH_CONFIG"
	sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 2/' "$SSH_CONFIG"

	# Add Protocol 2 if absent
	if ! grep -q "^Protocol 2" "$SSH_CONFIG"; then
		echo "Protocol 2" >>"$SSH_CONFIG"
	fi

	# Validate syntax
	if sshd -t; then
		systemctl restart sshd
		log success "✓ SSH hardened"
	else
		log error "SSH config validation failed, reverting"
		cp "$SSH_BACKUP" "$SSH_CONFIG"
		systemctl restart sshd
		die "SSH hardening reverted"
	fi
}

install_nftables() {
	log step "Installing nftables firewall"

	apt-get install -y nftables
	systemctl enable nftables

	log success "✓ nftables installed"
}

configure_firewall() {
	log step "Configuring nftables firewall (Beale ≤10 rules)"
	# Build nftables configuration in a temporary file and validate before applying
	local tmp_conf
	tmp_conf="/etc/nftables.conf.new"
	local now
	now=$(date -Iseconds)

	cat >"$tmp_conf" <<NFTABLES_CONF
#!/usr/sbin/nft -f
# FreeRADIUS Fortress Firewall (generated: $now)
# Management subnet: 10.0.1.0/27

flush ruleset

table inet filter {
  set radius_clients {
    type ipv4_addr
    flags interval
    elements = { 10.0.1.0/27 }
  }

  chain input {
    type filter hook input priority filter; policy drop;

    # 1: Accept loopback
    iifname lo accept

    # 2: Established/related
    ct state established,related accept

    # 3: SSH from management subnet only
    ip saddr 10.0.1.0/27 tcp dport 22 ct state new limit rate 50/second accept

    # 4: RADIUS auth (1812) from managed controllers/APs only
    ip saddr @radius_clients udp dport 1812 ct state new limit rate 200/second accept

    # 5: RADIUS accounting (1813) from managed controllers/APs only
    ip saddr @radius_clients udp dport 1813 ct state new accept

    # 6: LDAPS to DC subnet (allow new & established)
    ip saddr 10.0.10.0/26 tcp dport 636 ct state new,established accept

    # 7: DNS to Pi-hole / internal DNS (restricted)
    ip saddr 10.0.10.0/26 udp dport 53 ct state new accept

    # 8: NTP to trusted NTP servers (restricted)
    ip saddr 10.0.10.0/26 udp dport 123 ct state new accept

    # 9: ICMP (rate-limited)
    ip protocol icmp icmp type echo-request limit rate 10/second accept

    # 10: Log (rate-limited) then drop everything else
    limit rate 5/second counter log prefix "nft-drop: " drop
  }
}

# Minimal IPv6 policy (mirror IPv4 policy: deny by default, allow loopback & established)
table ip6 filter {
  chain input {
    type filter hook input priority filter; policy drop;
    iifname lo accept
    ct state established,related accept
    # Allow ICMPv6 neighbor discovery (required for IPv6)
    ip6 nexthdr icmpv6 accept
  }
}
NFTABLES_CONF

	chmod 644 "$tmp_conf"

	# Syntax check before applying (safe-apply)
	if ! nft -c -f "$tmp_conf" >/dev/null 2>&1; then
		rm -f "$tmp_conf"
		die "nftables configuration syntax check failed"
	fi

	# Backup existing config and apply new rules atomically
	if [[ -f /etc/nftables.conf ]]; then
		cp /etc/nftables.conf /etc/nftables.conf.bak || true
	fi

	mv "$tmp_conf" /etc/nftables.conf

	if nft -f /etc/nftables.conf >/dev/null 2>&1; then
		log success "✓ nftables configured (safe-apply, Beale compliant)"
	else
		# Attempt rollback
		if [[ -f /etc/nftables.conf.bak ]]; then
			mv /etc/nftables.conf.bak /etc/nftables.conf || true
			nft -f /etc/nftables.conf >/dev/null 2>&1 || true
		fi
		die "nftables application failed; original rules restored if available"
	fi
}

install_fail2ban() {
	log step "Installing fail2ban intrusion prevention"

	apt-get install -y fail2ban

	cat >/etc/fail2ban/jail.d/freeradius.conf <<'FAIL2BAN_CONF'
[freeradius]
enabled = true
port = 1812,1813
protocol = udp
filter = freeradius
logpath = /var/log/freeradius/radius.log
maxretry = 5
bantime = 3600
findtime = 600
FAIL2BAN_CONF

	# Create filter if missing
	if [[ ! -f /etc/fail2ban/filter.d/freeradius.conf ]]; then
		cat >/etc/fail2ban/filter.d/freeradius.conf <<'FILTER_CONF'
[Definition]
failregex = ^\w+\s+\d+ \d+:\d+:\d+ \S+ \S+\[\d+\]: Login incorrect: \[<HOST>
ignoreregex =
FILTER_CONF
	fi

	log success "✓ fail2ban configured"
}

configure_audit() {
	log step "Configuring audit logging"

	apt-get install -y auditd

	cat >/etc/audit/rules.d/freeradius.rules <<'AUDIT_RULES'
-w /etc/freeradius/ -p wa -k freeradius_config
-w /etc/freeradius/3.0/certs/ -p wa -k freeradius_certs
-w /var/log/freeradius/ -p wa -k freeradius_logs
AUDIT_RULES

	augenrules --load
	log success "✓ Audit logging configured"
}

configure_logging() {
	log step "Configuring FreeRADIUS logging"

	mkdir -p /var/log/freeradius
	chown freerad:freerad /var/log/freeradius
	chmod 750 /var/log/freeradius

	# Enable detailed logging
	sed -i 's/auth = no/auth = yes/' /etc/freeradius/3.0/radiusd.conf || true
	sed -i 's/auth_badpass = no/auth_badpass = yes/' /etc/freeradius/3.0/radiusd.conf || true
	sed -i 's/auth_goodpass = no/auth_goodpass = yes/' /etc/freeradius/3.0/radiusd.conf || true

	# Configure logrotate
	cat >/etc/logrotate.d/freeradius <<'LOGROTATE_CONF'
/var/log/freeradius/*.log {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  create 640 freerad freerad
  sharedscripts
  postrotate
    systemctl reload freeradius > /dev/null 2>&1 || true
  endscript
}
LOGROTATE_CONF

	log success "✓ Logging configured"
}

enable_services() {
	log step "Enabling hardening services"

	systemctl enable fail2ban auditd
	systemctl restart fail2ban auditd
	systemctl restart freeradius

	sleep 2

	if systemctl is-active --quiet fail2ban && systemctl is-active --quiet auditd; then
		log success "✓ All hardening services running"
	else
		die "Failed to start hardening services"
	fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	harden
fi
