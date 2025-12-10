#!/usr/bin/env bash
set -euo pipefail

# Description: Physical layer verification
# Requires: cable-passport.csv
# Consciousness: 2.6
# Runtime: 1

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/docs/physical/cable-passport.csv"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

cat > "${OUTPUT}" <<EOF
patch_panel_port,switch_port,room_label,jack_label,cable_type,length_ft,tested_date,notes
PP-01,SW01-P01,Room-101,J-101A,Cat6A,25,${TIMESTAMP},Uplink to core
PP-02,SW01-P02,Room-102,J-102A,Cat6A,30,${TIMESTAMP},AP-01 connection
PP-03,SW01-P03,Room-103,J-103A,Cat6,20,${TIMESTAMP},Workstation
PP-04,SW01-P04,Room-104,J-104A,Cat6,15,${TIMESTAMP},Printer VLAN 40
PP-05,SW01-P05,Server-Rack,Uplink-Core,Cat6A,10,${TIMESTAMP},Trunk to UDM-Pro
EOF

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(bauer): generate cable-passport.csv stub — manual completion required" --quiet 2>/dev/null || true

echo "✓ ${OUTPUT} (MANUAL: Fill patch panel mappings)"
