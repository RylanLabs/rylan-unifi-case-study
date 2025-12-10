#!/usr/bin/env bash
# runbooks/ministry-whispers/rylan-bauer-one-shot.sh
# Bauer (2005) — Trust Nothing, Verify Everything
# T3-ETERNAL v3.2: Key-only SSH, 10-rule lockdown. Idempotent. nmap-verified.
# Consciousness 2.6 — truth through subtraction.
# Execution: <30 seconds. Fail loudly on exposure.
set -euo pipefail

# === STEP 1: FETCH AUTHORIZED KEYS ===
echo "[BAUER] Fetching authorized keys..."
mkdir -p /root/.ssh && chmod 700 /root/.ssh

if curl -fsSL https://github.com/T-Rylander.keys -o /root/.ssh/authorized_keys 2>/dev/null; then
    :
else
    # Fallback to Carter ministry (post-rename)
    if [[ -f "/root/rylan-unifi-case-study/runbooks/ministry-secrets/rylan-carter-one-shot.sh" ]]; then
        bash /root/rylan-unifi-case-study/runbooks/ministry-secrets/rylan-carter-one-shot.sh
    else
        echo "FATAL: No keys available - deployment unsafe"
        exit 1
    fi
fi

chmod 600 /root/.ssh/authorized_keys

# === STEP 2: HARDEN SSH CONFIG ===
echo "[BAUER] Hardening SSH..."
SSH_CONF="/etc/ssh/sshd_config.d/99-bauer.conf"

if [[ -f "$SSH_CONF" ]]; then
    echo "[BAUER] Config exists — idempotent skip"
else
    cat > "$SSH_CONF" <<'EOF'
# Bauer (2005) — Trust Nothing, Verify Everything
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
fi

# === STEP 3: RELOAD + FAIL LOUD ===
sshd -t || { echo "FATAL: SSH config invalid"; sshd -t; exit 1; }
systemctl reload sshd || { echo "FATAL: SSH reload failed"; exit 1; }

# === STEP 4: WHITAKER PENTEST ===
echo "[BAUER] nmap validation..."
if command -v nmap >/dev/null; then
    if nmap -p 22 --script ssh-auth-methods localhost 2>/dev/null | grep -q "password"; then
        echo "FATAL: Password auth exposed"
        exit 1
    fi
else
    echo "WARN: nmap missing — manual verification required"
fi

cat <<'BANNER'
██████╗  █████╗ ██╗   ██╗███████╗██████╗ 
██╔══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗
██████╔╝███████║██║   ██║█████╗  ██████╔╝
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██╔══██╗
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
SSH KEY-ONLY. PASSWORD DEAD.
TRUST NOTHING. VERIFY EVERYTHING.
BANNER

echo "✅ [BAUER] Verification ministry deployed."