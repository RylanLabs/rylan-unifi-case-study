#!/bin/bash
set -euo pipefail
# Script: inventory/razer_phone_totp/setup-totp.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

echo "=== Razer Phone 2 → Eternal TOTP Beacon ==="
echo "Unlock → Developer Options → USB debugging ON → Enter"
read -r -p
adb install -r aegis-authenticator-3.1.apk
adb shell pm grant com.beemdevelopment.aegis android.permission.CAMERA
echo "Open Aegis → + → Scan QR for UniFi SSO and Samba AD"
echo "Export backup → /sdcard/AegisBackup.json (copy off-device now)"
echo "Phone stays tethered on VLAN 30 (static IP 10.0.30.45)"
