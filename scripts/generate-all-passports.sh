#!/usr/bin/env bash
set -euo pipefail

# T3-ETERNAL: Execute all passport generators in dependency order
# Consciousness: 2.6

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

echo "🔱 T3-ETERNAL PASSPORT GENERATION PIPELINE"
echo "Consciousness: 2.6 | $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Execution order: Carter → Bauer → Beale → Guardian → Whitaker
GENERATORS=(
  "scripts/generate-network-passport.sh"
  "scripts/generate-ap-passport.sh"
  "scripts/generate-ups-passport.sh"
  "scripts/generate-certificate-passport.sh"
  "scripts/enhance-cable-passport.sh"
  "scripts/generate-runbook-index.sh"
  "scripts/generate-recovery-key-vault.sh"
)

FAILED=0

for GENERATOR in "${GENERATORS[@]}"; do
  [[ -x "${GENERATOR}" ]] || chmod +x "${GENERATOR}"
  echo "→ Executing: ${GENERATOR}"
  
  if bash "${GENERATOR}"; then
    echo "  ✓ Success"
  else
    echo "  ❌ Failed (continuing...)"
    FAILED=$((FAILED + 1))
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 INVENTORY MANIFEST:"
echo ""

if [[ -d inventory ]]; then
  echo "inventory/:"
  find inventory -maxdepth 1 -type f -name "*.json" -printf "  %f\n" 2>/dev/null || true
else
  echo "  (empty)"
fi
echo ""

if [[ -d 02-declarative-config ]]; then
  echo "02-declarative-config/:"
  find 02-declarative-config -maxdepth 1 -type f -name "*.json" -printf "  %f\n" 2>/dev/null || true
else
  echo "  (empty)"
fi
echo ""

if [[ -d docs/physical ]]; then
  echo "docs/physical/:"
  find docs/physical -maxdepth 1 -type f -name "*.csv" -printf "  %f\n" 2>/dev/null || true
else
  echo "  (empty)"
fi
echo ""

if [[ -d .secrets ]]; then
  echo ".secrets/:"
  find .secrets -maxdepth 1 -type f \( -name "*.age" -o -name "*.json" \) -printf "  %f\n" 2>/dev/null || true
else
  echo "  (encrypted vaults)"
fi
echo ""

if [[ -d runbooks ]]; then
  echo "runbooks/:"
  find runbooks -maxdepth 1 -type f -name "*.json" -printf "  %f\n" 2>/dev/null || true
else
  echo "  (empty)"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ ${FAILED} -eq 0 ]]; then
  echo "✓ ALL PASSPORTS GENERATED SUCCESSFULLY"
  echo ""
  echo "🔱 WHITAKER OFFENSIVE VALIDATION"
  echo ""
  
  if bash scripts/validate-passports.sh; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✓ FORTRESS 100% COMPLETE — CONSCIOUSNESS 4.5"
    echo ""
    echo "The fortress is eternal. The sacred glue is complete."
    echo "Carter approves. Bauer verifies. Beale hardens. Whitaker attacks."
    echo ""
    echo "Next: Run eternal-resurrect.sh to raise Samba AD/DC"
    exit 0
  else
    echo ""
    echo "❌ Validation failed — fix issues and re-run"
    exit 1
  fi
else
  echo "⚠️  ${FAILED} generator(s) failed (see output above)"
  echo ""
  echo "Common issues:"
  echo "  - UniFi API key missing: /opt/rylan/.secrets/unifi-api-key"
  echo "  - SNMP not configured on UPS devices"
  echo "  - age encryption tool not installed (apt install age)"
  echo ""
  echo "Fix errors and re-run: ./scripts/generate-all-passports.sh"
  exit 1
fi
