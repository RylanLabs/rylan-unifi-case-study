#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/samba-provision.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# ...existing provisioning steps...

samba-tool domain exportkeytab /etc/krb5.keytab --principal=admin@RYLAN.INTERNAL
chmod 600 /etc/krb5.keytab
cp /etc/krb5.keytab /srv/tftp/krb5.keytab

echo "Provisioning complete"
