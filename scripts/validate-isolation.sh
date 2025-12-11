#!/bin/bash
# Bauer/Whitaker: nmap VLAN Check
set -euo pipefail
nmap -sV --top-ports 10 10.0.{10,30,40,90}.0/24 | grep -c "open" | grep -q 0 || {
  echo "❌ Leak detected"
  exit 1
}
echo "🔒 Isolation validated" >&2
