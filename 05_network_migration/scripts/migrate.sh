#!/bin/bash
set -euo pipefail
# Script: 05_network_migration/scripts/migrate.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# Migrate: Render Desired → Backup → Push → Verify
# Author: DT/Luke canonical
# Date: 2025-12-10
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME
cd "$(dirname "$0")/.."

# Pre-flight: Backup (Hellodeolu: RTO <15 min)
mkdir -p backups

source ../runbooks/ministry_secrets/rylan-carter-eternal-one-shot.sh
unifi_get_networks >"backups/pre-migration-$(date +%Y%m%d-%H%M%S).json"
echo "💾 Backup saved to backups/"

# Render + Push
python ../02_declarative_config/apply.py --render-only
unifi_push_network "$(cat configs/vlans.json)"
unifi_push_network "$(cat configs/firewall-rules.json)"

# Post-verify (Bauer: Trust Nothing)
../scripts/validate-isolation.sh
echo "🛡️ Migration complete. Rollback: ./rollback.sh | RTO <15 min validated."
