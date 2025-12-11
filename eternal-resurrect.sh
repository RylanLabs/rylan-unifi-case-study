#!/bin/bash
# Eternal Resurrect v∞.3.2 – One-Command Fortress (15 min RTO)
set -euo pipefail
IFS=$'\n\t'

# Diagnostics: log() + die() (Beale: Detect Heresy)
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
  exit 1
}

# run_ministry(): Diagnostic wrapper for Trinity isolation (Bauer: Verify Step)
run_ministry() {
  local ministry="$1"
  local script="$2"
  log "Running $ministry: $script"
  if ! "runbooks/$ministry/$script"; then
    die "$ministry failed (exit $?); check logs above"
  fi
  log "✅ $ministry complete"
}

log "🛡️ Raising Eternal Fortress..."

# Detect execution modes (Bauer: Verify Environment)
DRY_RUN="${DRY_RUN:-0}"
CI_MODE="${CI:-0}"

if [ "$DRY_RUN" = "1" ] || [ "$DRY_RUN" = "true" ]; then
  log "🧪 Smoke-test mode: DRY_RUN enabled (skipping actual deployment)"
fi

if [ "$CI_MODE" = "1" ] || [ "$CI_MODE" = "true" ]; then
  log "🤖 CI mode: Mocking services, skipping external calls"
fi

# Carter → Bauer → Beale (skip in DRY_RUN smoke test; validate in prod)
if [ "$DRY_RUN" != "1" ] && [ "$DRY_RUN" != "true" ]; then
  run_ministry "ministry-secrets" "rylan-carter-eternal-one-shot.sh"
  run_ministry "ministry-whispers" "rylan-bauer-eternal-one-shot.sh"
  run_ministry "ministry-detection" "rylan-beale-eternal-one-shot.sh"
else
  log "⏭️  Trinity mocked in DRY_RUN (validation deferred to prod)"
fi

# Bootstrap + Migration (skip in DRY_RUN)
if [ "$DRY_RUN" != "1" ] && [ "$DRY_RUN" != "true" ]; then
  log "Invoking bootstrap + migration..."
  01-bootstrap/unifi/inventory-devices.sh || die "Inventory devices failed"
  05-network-migration/scripts/migrate.sh || die "Network migration failed"

  # Whitaker Validation
  log "Invoking Whitaker validation..."
  scripts/validate-isolation.sh || die "Isolation validation failed"
  scripts/simulate-breach.sh || die "Breach simulation failed"
else
  log "⏭️  Skipping deployment scripts (DRY_RUN mode)"
fi

# Hellodeolu: Outcomes Check (mock in CI/DRY_RUN)
if [ "$CI_MODE" = "1" ] || [ "$DRY_RUN" = "1" ]; then
  log "✅ Service count check: mocked in CI/DRY_RUN"
else
  log "Verifying service count..."
  [[ $(systemctl list-units --state=running | wc -l) -lt 50 ]] || die "Too many services (>50 running)"
fi

log "✅ Fortress risen. Consciousness: 3.9"
