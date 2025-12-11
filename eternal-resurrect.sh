#!/bin/bash
# Eternal Resurrect v∞.3.2 – One-Command Fortress (15 min RTO)
set -euo pipefail
echo "🛡️ Raising Eternal Fortress..." >&2

# Detect execution modes (Bauer: Verify Environment)
DRY_RUN="${DRY_RUN:-0}"
CI_MODE="${CI:-0}"

if [ "$DRY_RUN" = "1" ] || [ "$DRY_RUN" = "true" ]; then
  echo "🧪 Smoke-test mode: DRY_RUN enabled (skipping actual deployment)" >&2
fi

if [ "$CI_MODE" = "1" ] || [ "$CI_MODE" = "true" ]; then
  echo "🤖 CI mode: Mocking services, skipping external calls" >&2
fi

# Carter → Bauer → Beale
runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh
runbooks/ministry-whispers/rylan-bauer-eternal-one-shot.sh
runbooks/ministry-detection/rylan-beale-eternal-one-shot.sh

# Bootstrap + Migration (skip in DRY_RUN)
if [ "$DRY_RUN" != "1" ] && [ "$DRY_RUN" != "true" ]; then
  01-bootstrap/unifi/inventory-devices.sh
  05-network-migration/scripts/migrate.sh

  # Whitaker Validation
  scripts/validate-isolation.sh
  scripts/simulate-breach.sh
else
  echo "⏭️  Skipping deployment scripts (DRY_RUN mode)" >&2
fi

# Hellodeolu: Outcomes Check (mock in CI/DRY_RUN)
if [ "$CI_MODE" = "1" ] || [ "$DRY_RUN" = "1" ]; then
  echo "✅ Service count check: mocked in CI/DRY_RUN" >&2
else
  [[ $(systemctl list-units --state=running | wc -l) -lt 50 ]] || { echo "❌ Too many services"; exit 1; }
fi

echo "✅ Fortress risen. Consciousness: 3.9" >&2
