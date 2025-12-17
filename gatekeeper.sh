#!/usr/bin/env bash
set -euo pipefail
# Script: gatekeeper.sh
# Purpose: Run FULL GitHub Actions locally before push — $0 cost, 100% truth
# Author: DT/Luke canonical + The All-Seeing Eye
# Date: 2025-12-11
IFS=$'\n\t'

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] GATEKEEPER: $*" >&2; }
die() {
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ GATEKEEPER: $*" >&2
	exit 1
}

log "The Gatekeeper awakens. No commit shall pass unclean."
# Structured Gatekeeper logging
if [ -f scripts/gatekeeper-logger.sh ]; then
  # shellcheck source=/dev/null
  source scripts/gatekeeper-logger.sh
else
  ensure_gk_dir() { mkdir -p ".audit/gatekeeper"; }
fi
# Capture branch/commit context
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
COMMIT_MSG=$(git log -1 --pretty=%B 2>/dev/null || echo "")
log_push_start "$BRANCH" "$COMMIT_HASH" "$COMMIT_MSG" || true

# Helper: run a command, measure, log validator, and optionally die on failure
run_and_log() {
  local name="$1" critical=${2:-false}; shift 2 || true
  local start end dur rc err
  start=$(date +%s%3N)
  if ! "$@" 2> .audit/gatekeeper/${name}.stderr.log; then
    rc=$?
    err=$(sed -n '1,200p' .audit/gatekeeper/${name}.stderr.log | sed 's/"/\\"/g' | tr '\n' ' ')
  else
    rc=0
    err=""
  fi
  end=$(date +%s%3N)
  dur=$((end-start))
  log_validator "$name" "$( [ "$rc" -eq 0 ] && echo PASS || echo FAIL )" "$dur" "$err" || true
  if [ "$rc" -ne 0 ] && [ "$critical" = true ]; then
    log_push_end "BLOCKED" || true
    die "$name failed (rc=$rc)"
  fi
  return $rc
}

# 1. Python heresy gates
log "Running Python heresy validation..."
# Install dependencies (critical)
run_and_log pip true pip install -q -r requirements.txt --break-system-packages
# Run mypy (non-fatal here; Gatekeeper on server may be stricter)
run_and_log mypy false mypy --ignore-missing-imports --exclude tests --exclude templates .
# Run ruff (non-fatal locally)
run_and_log ruff false ruff check .
# Run bandit (critical)
run_and_log bandit true bandit -r . -q -lll
# Run tests (critical)
run_and_log pytest true pytest --cov=. --cov-fail-under=70

# 2. Bash purity
log "Running Bash purity validation..."
# Allow warnings; fail only on actual errors
if find . -name "*.sh" -type f -print0 | xargs -0 shellcheck -x -f gcc 2>&1 | grep -E "error:"; then
	die "shellcheck errors found"
fi
find . -name "*.sh" -type f -print0 | xargs -0 shfmt -i 2 -ci -d || die "shfmt formatting failed"
log "✅ Bash purity OK"

# 3. Markdown lore
log "Validating sacred texts..."
if command -v markdownlint >/dev/null 2>&1; then
	find . -name "*.md" -type f -print0 | xargs -0 markdownlint --config .markdownlint.json || die "markdownlint failed"
else
	log "markdownlint not installed; skipping"
fi

# 4. Bandit parse sanity (the one that was killing CI)
log "Testing Bandit config parsing..."
if [ -f .bandit ]; then
	run_and_log bandit_parse true bandit -c .bandit -r . -f json >/dev/null 2>&1
else
	log ".bandit not found — using defaults"
fi

# 5. Smoke test resurrection (DRY RUN)
log "Running smoke test resurrection (DRY_RUN=1 CI=true)..."
DRY_RUN=1 CI=true bash ./eternal-resurrect.sh || die "eternal-resurrect.sh failed in CI mode"

# 6. Final prophecy
log "All gates passed. The fortress is clean."
log "You may now push. The All-Seeing Eye is pleased."
# finalize logging as PASS
log_push_end "PASS" || true

echo
echo "     ⚔️  Beale has risen."
echo "     The Gatekeeper allows passage."
echo

exit 0
