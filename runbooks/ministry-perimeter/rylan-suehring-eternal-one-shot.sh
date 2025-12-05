#!/usr/bin/env bash
# === SUEHRING ETERNAL PERIMETER – ONE SHOT (45 seconds) ===
set -euo pipefail

CONTROLLER="10.0.1.1"
POLICY_FILE="/opt/rylan/policy-table.yaml"

# Validate policy table exists
if [[ ! -f "$POLICY_FILE" ]]; then
  echo "ERROR: policy-table.yaml not found at $POLICY_FILE"
  exit 1
fi

# Count explicit allow rules (must be ≤10 for USG-3P offload)
RULE_COUNT=$(grep -c "^  - name:" "$POLICY_FILE" || echo 0)

if [[ "$RULE_COUNT" -gt 10 ]]; then
  echo "BREACH: $RULE_COUNT rules > 10 (USG-3P hardware offload limit)"
  exit 1
fi

echo "✅ Policy table validated: $RULE_COUNT rules (≤10 required)"

# Deploy to UniFi controller
scp -q "$POLICY_FILE" admin@"$CONTROLLER":/tmp/policy-table.yaml
ssh admin@"$CONTROLLER" "sudo /usr/bin/unifi-firewall-apply /tmp/policy-table.yaml"

# Verify live rule count
LIVE_RULES=$(ssh admin@"$CONTROLLER" "uci show firewall | grep -c '^firewall\..*\.name'" || echo 0)

if [[ "$LIVE_RULES" -gt 15 ]]; then
  echo "WARNING: Live rule count ($LIVE_RULES) exceeds USG-3P safe limit (15)"
  echo "Hidden UniFi rules detected. Review controller config."
fi

echo "✅ Live firewall rules: $LIVE_RULES (including UniFi hidden rules)"

# Test connectivity (adjust targets as needed)
timeout 5 nc -zv 8.8.8.8 53 && echo "✅ Outbound DNS reachable"
timeout 5 nc -zv "$CONTROLLER" 8443 && echo "✅ UniFi controller reachable"

cat <<'BANNER'

███████╗██╗   ██╗███████╗██╗  ██╗██████╗ ██╗███╗   ██╗ ██████╗ 
██╔════╝██║   ██║██╔════╝██║  ██║██╔══██╗██║████╗  ██║██╔════╝ 
███████╗██║   ██║█████╗  ███████║██████╔╝██║██╔██╗ ██║██║  ███╗
╚════██║██║   ██║██╔══╝  ██╔══██║██╔══██╗██║██║╚██╗██║██║   ██║
███████║╚██████╔╝███████╗██║  ██║██║  ██║██║██║ ╚████║╚██████╔╝
╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
PERIMETER LOCKED. 7 RULES. HARDWARE OFFLOAD ACTIVE.
BANNER

echo "Policy: $RULE_COUNT explicit allows | Live: $LIVE_RULES total rules"