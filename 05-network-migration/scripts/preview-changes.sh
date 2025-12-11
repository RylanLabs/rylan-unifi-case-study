#!/bin/bash
# Preview: Desired YAML vs Live Controller (Diff for Safety)
# Author: DT/Luke canonical
# Date: 2025-12-10
set -euo pipefail
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034
readonly SCRIPT_NAME
cd "$(dirname "$0")/.."

echo "🔍 Rendering desired state..."
python ../02-declarative-config/apply.py --render-only

echo "📊 Diff: Desired vs Live..."
# Render live (via API – silent on match)# shellcheck disable=SC1091source ../runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
LIVE_VLANS=$(unifi_get_networks | jq '.[] | select(.vlan != 1) | {vlan: .vlan, name: .name, subnet: .subnet}' | jq -s '{vlans: .}')
echo "$LIVE_VLANS" >/tmp/live-vlans.json

# Diff (jq sort for stability)
diff -u \
  <(jq -S . configs/vlans.json) \
  <(echo "$LIVE_VLANS" | jq -S .) || true

rm -f /tmp/live-vlans.json
echo "✅ Preview complete. Green diff → safe to migrate. Run ./scripts/migrate.sh when ready."
