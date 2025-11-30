#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "   Rylan Overhaul v5.0 — Ignite Orchestrator   "
echo "==============================================="

echo "[1/4] Dry-run reconciliation"
python "$(dirname "$0")/../02-declarative-config/apply.py" --dry-run

read -p "Apply changes? [y/N] " RESP
if [[ "${RESP:-N}" =~ ^[Yy]$ ]]; then
  echo "[2/4] Applying changes"
  python "$(dirname "$0")/../02-declarative-config/apply.py" --apply
else
  echo "Skipped apply. Exiting after dry-run."
fi

echo "[3/4] Validating isolation"
"$(dirname "$0")/../03-validation-ops/validate-isolation.sh"

echo "[4/4] Deploy complete — https://$(hostname -I | awk '{print $1}'):8443"
