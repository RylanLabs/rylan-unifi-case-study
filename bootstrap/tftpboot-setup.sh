#!/bin/bash
set -euo pipefail
# Script: bootstrap/tftpboot-setup.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

set -e
sudo mkdir -p /var/lib/tftpboot
cd /var/lib/tftpboot
sudo wget -q http://boot.ipxe.org/undionly.kpxe
sudo wget -q http://boot.ipxe.org/ipxe.efi
echo "iPXE binaries deployed"
