#!/usr/bin/env bash
set -euo pipefail
echo "Validating rylan-dc foundations..."
ip addr show eno1 | grep -E "(10\.0\.10\.10|10\.0\.30\.10)" || { echo "FAIL: netplan not applied"; exit 1; }
ping -c 1 -W 1 10.0.10.11 >/dev/null 2>&1 && { echo "FAIL: 10.0.10.11 conflict"; exit 1; } || echo "OK: 10.0.10.11 free"
sudo samba-tool domain info 127.0.0.1 >/dev/null || { echo "FAIL: Samba AD not responding"; exit 1; }
echo "All checks passed"
