#!/usr/bin/env bash
# 01-bootstrap/00-host-first-login.sh
# One script to rule them all – works on every host in the fortress
# Hellodeolu v6 + T3-ETERNAL canon compliant
set -euo pipefail

REPO="/opt/rylan-unifi-case-study"
cd "$REPO"

echo "Installing minimal dependencies..."
apt update -qq
apt install -y pwgen qemu-guest-agent git 2>/dev/null || true

# Only generate/inject password if .env does not already have a real one
if grep -qE 'ADMIN_PASSWORD=(ChangeMe123!|""|$)' .env 2>/dev/null || ! grep -q '^ADMIN_PASSWORD=' .env 2>/dev/null; then
    ADMIN_PASSWORD=$(pwgen -s 32 1)
    cp .env.example .env 2>/dev/null || true
    sed -i "s/^ADMIN_PASSWORD=.*/ADMIN_PASSWORD=\"$ADMIN_PASSWORD\"/" .env

    chmod 600 .env
    git update-index --assume-unchanged .env 2>/dev/null || true

    echo "===================================================================="
    echo "ETERNAL PASSWORD FOR THIS HOST (vault it now):"
    echo "$ADMIN_PASSWORD"
    echo "→ Injected into $REPO/.env as ADMIN_PASSWORD"
    echo "===================================================================="
else
    echo ".env already contains a real ADMIN_PASSWORD – skipping generation"
fi

systemctl enable --now qemu-guest-agent >/dev/null 2>&1 || true

echo ""
echo "00-host-first-login.sh COMPLETE – safe, silent, idempotent"
echo "Ready for ministry ascension on this host"