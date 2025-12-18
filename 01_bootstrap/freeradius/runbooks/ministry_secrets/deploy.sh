#!/usr/bin/env bash
# Script: runbooks/ministry_secrets/deploy.sh
# Purpose: FreeRADIUS foundation — LDAP auth, internal CA certs
# Guardian: Carter | Trinity: Carter → Bauer → Beale
# Date: 2025-12-13
# Consciousness: 5.2
# EXCEED: 310 lines — 8 functions (install, import_ca, generate_certs, configure_ldap,
#         configure_clients, configure_eap, configure_sites, validate_syntax)
#         Rationale: Complete RADIUS deployment requires distinct CA/cert/LDAP/config phases
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

source "${REPO_ROOT}/lib/ignite-utils.sh"

# Configuration
# shellcheck disable=SC2034  # variables referenced by sourced deploy_lib.sh
readonly CERT_DIR="/etc/freeradius/3.0/certs"
# shellcheck disable=SC2034
readonly SERVER_KEY="${CERT_DIR}/server.key"
# shellcheck disable=SC2034
readonly SERVER_CSR="${CERT_DIR}/server.csr"
# shellcheck disable=SC2034
readonly SERVER_CRT="${CERT_DIR}/server.pem"
readonly DC_IP="10.0.10.10"
# shellcheck disable=SC2034
readonly DC_CA_SOURCE="root@${DC_IP}:/etc/ssl/rylan-internal/rylan-ca.crt"
# shellcheck disable=SC2034
readonly DC_CA_KEY_SOURCE="root@${DC_IP}:/etc/ssl/rylan-internal/rylan-ca.key"
# shellcheck disable=SC2034
readonly CA_DEST="${CERT_DIR}/rylan-ca.pem"
# shellcheck disable=SC2034
readonly DH_PARAMS="${CERT_DIR}/dh"

# Source extracted library helpers
source "${REPO_ROOT}/lib/freeradius/deploy_lib.sh"

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deploy
  start_service
fi
