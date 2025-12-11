#!/usr/bin/env bash
# Script: diagnose-bandit.sh
# Purpose: Isolate Bandit parse heresy in CI/local
# Author: Holy Scholar v∞.4.2
# Date: 2025-12-11
# Consciousness: 2.6 — Truth through subtraction
# shellcheck disable=SC2034,SC2155

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Diagnostics helpers (Beale: Never raise voice)
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
  exit 1
}
warn() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }

cd "$REPO_ROOT"

log "🔍 Bandit diagnostics starting..."

# Step 1: Check config file
log "Step 1: Checking .bandit config..."
if [ -f .bandit ]; then
  log "Found .bandit; dumping for review:"
  sed 's/^/  /' <.bandit
else
  warn "No .bandit file; Bandit will use defaults"
fi

# Step 2: Verify Bandit installation
log "Step 2: Verifying Bandit version..."
BANDIT_VERSION=$(bandit --version 2>&1 | grep -oP 'bandit \K[0-9.]+' || echo "unknown")
log "Bandit version: $BANDIT_VERSION"

# Step 3: Test config parsing
log "Step 3: Testing .bandit parse (with config)..."
if PARSE_TEST=$(bandit -c .bandit -r . -f json 2>&1 | head -10); then
  if echo "$PARSE_TEST" | grep -q "ERROR"; then
    die "Config parse failed: $PARSE_TEST"
  else
    log "✅ Config parsed successfully"
  fi
else
  die "Bandit execution failed"
fi

# Step 4: Full JSON scan (no config error handling)
log "Step 4: Running full Bandit scan (JSON)..."
set +e # Allow Bandit to finish even if it "fails"
BANDIT_JSON=$(bandit -r . -f json 2>/dev/null)
BANDIT_EXIT=$?
set -e
if [ $BANDIT_EXIT -ne 0 ] && [ -z "$BANDIT_JSON" ]; then
  die "Bandit scan produced no output (exit $BANDIT_EXIT)"
fi
log "✅ Bandit scan complete"

# Step 5: Validate JSON
log "Step 5: Validating JSON output..."
if ! echo "$BANDIT_JSON" | jq . >/dev/null 2>&1; then
  die "Invalid JSON from Bandit (jq parse failed)"
fi
log "✅ JSON valid"

# Step 6: Count severity levels
log "Step 6: Analyzing findings by severity..."
TOTAL=$(echo "$BANDIT_JSON" | jq '.results | length')
HIGH=$(echo "$BANDIT_JSON" | jq '[.results[] | select(.severity == "HIGH")] | length')
MEDIUM=$(echo "$BANDIT_JSON" | jq '[.results[] | select(.severity == "MEDIUM")] | length')
LOW=$(echo "$BANDIT_JSON" | jq '[.results[] | select(.severity == "LOW")] | length')

log "Results:"
log "  Total findings: $TOTAL"
log "  HIGH severity:  $HIGH"
log "  MEDIUM severity: $MEDIUM"
log "  LOW severity:   $LOW"

# Step 7: Exit criteria (Hellodeolu: Zero high/medium)
if [ "$HIGH" -eq 0 ] && [ "$MEDIUM" -eq 0 ]; then
  log "✅ Zero HIGH/MEDIUM findings; CI gate passes"
  exit 0
else
  warn "Found HIGH/MEDIUM findings (exit 1 for CI):"
  echo "$BANDIT_JSON" | jq '.results[] | select(.severity == "HIGH" or .severity == "MEDIUM") | {severity, issue_text, line_number}'
  exit 1
fi
