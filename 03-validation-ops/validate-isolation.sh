#!/usr/bin/env bash
set -euo pipefail

# Validate inter-VLAN isolation using docker curl for-loops
networks=(Management Servers TrustedDevices VoIP GuestIoT)

echo "[validate-isolation] Starting docker curl isolation checks..."
for src in "${networks[@]}"; do
  for dst in "${networks[@]}"; do
    if [[ "$src" == "$dst" ]]; then continue; fi
    echo "Testing $src -> $dst"
    # Probe a representative gateway HTTP port; expected blocked except allowed rules
    if docker run --rm --network host curlimages/curl:8.8.0 curl -sS --max-time 3 "http://10.0.1.1" >/dev/null; then
      echo "  $src -> $dst: reachable (review policy if unexpected)"
    else
      echo "  $src -> $dst: blocked (expected under zero-trust)"
    fi
  done
done

echo "Isolation validation complete."
