#!/bin/bash
set -e
sudo mkdir -p /var/lib/tftpboot
cd /var/lib/tftpboot
sudo wget -q http://boot.ipxe.org/undionly.kpxe
sudo wget -q http://boot.ipxe.org/ipxe.efi
echo "iPXE binaries deployed"
