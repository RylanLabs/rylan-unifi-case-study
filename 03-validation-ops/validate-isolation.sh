#!/usr/bin/env bash
# Simple inter-VLAN isolation validator.
# Requires reachability from a host with curl to target IPs.

set -euo pipefail

echo "[validate-isolation] Starting checks..."

# Define sample probes (src executed from management context)
PROBES=(
  "10.0.10.1"  # IoT gateway
  "10.0.30.1"  # Guest gateway
)

FAILED=0
for ip in "${PROBES[@]}"; do
  echo "Checking TCP/80 reachability to $ip (expected: blocked)..."
  if curl -m 2 -s "http://$ip" >/dev/null; then
    echo "❌ Isolation failure: $ip responded on port 80"
    FAILED=1
  else
    echo "✅ $ip unreachable as expected"
  fi
done

if [ $FAILED -eq 0 ]; then
  echo "All isolation checks passed."; exit 0
else
  echo "One or more isolation checks failed."; exit 1
fi
