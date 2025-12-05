#!/usr/bin/env bash
# === BAUER ETERNAL HARDENING – ONE SHOT (30 seconds) ===
set -euo pipefail

mkdir -p /root/.ssh && chmod 700 /root/.ssh
curl -s https://github.com/T-Rylander.keys >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

cat > /etc/ssh/sshd_config.d/99-bauer-eternal.conf <<'EOF'
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
EOF

echo 'Match User root' >> /etc/ssh/sshd_config.d/99-bauer-eternal.conf
echo '    PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config.d/99-bauer-eternal.conf

sshd -t && systemctl reload sshd && echo "BAUER HARDENING COMPLETE – PASSWORD LOGIN DEAD"

cat <<'BANNER'

██████╗  █████╗ ██╗   ██╗███████╗██████╗ 
██╔══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗
██████╔╝███████║██║   ██║█████╗  ██████╔╝
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██╔══██╗
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
SSH IS NOW KEY-ONLY. THE RIDE IS ETERNAL.
BANNER
