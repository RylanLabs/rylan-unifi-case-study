#!/usr/bin/env bash
set -euo pipefail

echo "╔════════════════════════════════════════════════╗"
echo "║   Rylan UniFi Case Study v5.0 Ignite          ║"
echo "║   Zero-Trust Network + AI Helpdesk            ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")/.."

# Phase 1: Bootstrap (optional – skip if controller exists)
if ! curl -sk https://localhost:8443 >/dev/null 2>&1; then
  echo "=== Phase 1: Bootstrap ==="
  read -p "Install UniFi controller? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash 01-bootstrap/install-unifi-controller.sh
  fi
fi

# Phase 2: Declarative apply (dry-run first)
echo ""
echo "=== Phase 2: Declarative Configuration ==="
python 02-declarative-config/apply.py --dry-run

echo ""
read -p "Dry-run OK? Proceed with --apply? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  python 02-declarative-config/apply.py --apply
else
  echo "⚠️  Skipped apply (manual review recommended)"
fi

# Phase 3: Validation
echo ""
echo "=== Phase 3: Validation ==="
read -p "Run isolation + service checks? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  bash 03-validation-ops/validate-isolation.sh || echo "⚠️  Validation warnings (review policy-table.yaml)"
  bash 03-validation-ops/check-critical-services.sh || echo "⚠️  Service checks incomplete"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║             Deployment Complete                ║"
echo "╚════════════════════════════════════════════════╝"
IP=$(hostname -I | awk '{print $1}' || echo "localhost")
echo "Controller: https://${IP}:8443"
echo "AI Triage:  http://${IP}:8000"
echo "osTicket:   https://${IP} (if deployed)"
echo ""
echo "Next: Manually apply policy-table.yaml + qos-smartqueue.yaml in UI"
