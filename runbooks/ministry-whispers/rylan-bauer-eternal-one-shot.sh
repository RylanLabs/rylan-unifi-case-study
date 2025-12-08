#!/usr/bin/env bash
# === BAUER ETERNAL HARDENING v6 — MINISTRY OF BAUER (30 seconds) ===
# runbooks/ministry-bauer/rylan-bauer-eternal-one-shot.sh
# Bauer (2005) — Trust Nothing, Verify Everything
# T3-ETERNAL: Key-only SSH. No passwords. Idempotent. nmap-verified.
# Commit: feat/t3-eternal-v6-bauer | Tag: v6.0.0-bauer
set -euo pipefail

# === STEP 1: Fetch Carter's Keys (GitHub or local) ===
echo "[BAUER] Fetching authorized keys..."
mkdir -p /root/.ssh && chmod 700 /root/.ssh

if curl -fsSL https://github.com/T-Rylander.keys -o /root/.ssh/authorized_keys 2>/dev/null; then
    echo "  [OK] Keys fetched from GitHub"
else
    echo "  [WARN] GitHub fetch failed - checking local carter-banner-drop.sh"
    if [[ -f "/root/rylan-unifi-case-study/runbooks/ministry-carter/carter-banner-drop.sh" ]]; then
        bash /root/rylan-unifi-case-study/runbooks/ministry-carter/carter-banner-drop.sh
    else
        echo "  [FATAL] No keys available - deployment unsafe"
        exit 1
    fi
fi

chmod 600 /root/.ssh/authorized_keys

# === STEP 2: Harden SSH (Bauer's Silence) ===
echo "[BAUER] Hardening SSH config..."
cat > /etc/ssh/sshd_config.d/99-bauer-eternal.conf <<'EOF'
# === BAUER ETERNAL HARDENING v6 ===
PasswordAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
ChallengeResponseAuthentication no
PermitEmptyPasswords no
ClientAliveInterval 60
ClientAliveCountMax 3
MaxAuthTries 3
LoginGraceTime 20
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PermitTunnel no
UsePAM yes

Match User root
    PermitRootLogin prohibit-password
EOF

# === STEP 3: Reload + Fail Loud ===
sshd -t || { echo "[FATAL] SSH config invalid"; exit 1; }
systemctl reload sshd || { echo "[FATAL] SSH reload failed"; exit 1; }

# === STEP 4: Whitaker Pentest (local nmap sim) ===
echo "[BAUER] Validating with nmap..."
if command -v nmap >/dev/null; then
    if nmap -p 22 --script ssh-auth-methods localhost 2>/dev/null | grep -q "password"; then
        echo "[FATAL] Password auth still exposed"
        exit 1
    fi
    echo "  [OK] Password auth DEAD (nmap verified)"
else
    echo "  [WARN] nmap not installed - manual verification required"
fi

cat <<'BANNER'

██████╗  █████╗ ██╗   ██╗███████╗██████╗ 
██╔══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗
██████╔╝███████║██║   ██║█████╗  ██████╔╝
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██╔══██╗
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
SSH IS NOW KEY-ONLY. PASSWORD LOGIN DEAD.
THE RIDE IS ETERNAL.
BANNER
