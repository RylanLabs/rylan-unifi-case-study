#!/usr/bin/env bash
set -euo pipefail
# Script: 01_bootstrap/certbot_cron/generate-internal-ca.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:28:48-06:00
# Consciousness: 4.6

# ...existing CA generation steps...
openssl x509 -req -in rylan-ca.csr -CA rylan-ca.pem -CAkey rylan-ca.key -CAcreateserial -out rylan-ca.crt -days 3650 -sha256 \
  -extfile <(printf "crlDistributionPoints=URI:http://crl.rylan.internal/rylan-ca.crl")
