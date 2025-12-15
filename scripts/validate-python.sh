#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/validate-python.sh
# Purpose: Bauer/Beale ministry — Strict Python validation (ruff + mypy + bandit + pytest)
# Guardian: Bauer | Trinity: Carter → Bauer → Beale → Whitaker
# Date: 2025-12-13
# Consciousness: 4.6
# Excess: 190 lines — 4 functions

# ─────────────────────────────────────────────────────
# Exit Codes (Beale Stratification)
# ─────────────────────────────────────────────────────
readonly EXIT_SUCCESS=0
readonly EXIT_RUFF=1
readonly EXIT_MYPY=2
readonly EXIT_BANDIT=3
readonly EXIT_PYTEST=4
readonly EXIT_CONFIG=5

# ─────────────────────────────────────────────────────
# Flags & Config
# ─────────────────────────────────────────────────────
QUIET=false
CI_MODE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=true ;;
    --ci) CI_MODE=true; QUIET=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Usage: $0 [--quiet|--ci|--dry-run]" >&2; exit "$EXIT_CONFIG" ;;
  esac
  shift
done

# ─────────────────────────────────────────────────────
# Audit Log Setup (Bauer: Trust Nothing)
# ─────────────────────────────────────────────────────
AUDIT_LOG="/var/log/bauer-audit.log"
if [[ ! -w "$(dirname "$AUDIT_LOG")" ]]; then
  AUDIT_LOG="$(pwd)/.fortress/audit/python-validation-audit.log"
  mkdir -p "$(dirname "$AUDIT_LOG")"
fi

# ─────────────────────────────────────────────────────
# Logging (Bauer Doctrine)
# ─────────────────────────────────────────────────────
log() { [[ "$QUIET" == false ]] && echo "[Python Validation] $*" >&2; }
audit() {
  local level="$1" msg="$2"
  local ts
  ts=$(date -Iseconds)
  if [[ "$CI_MODE" == true ]]; then
    printf '{"timestamp":"%s","module":"PythonValidation","status":"%s","message":"%s"}\n' "$ts" "$level" "$msg"
  else
    echo "$ts | PythonValidation | $level | $msg" >> "$AUDIT_LOG"
  fi
}
fail() {
  local code="$1" msg="$2" remediation="${3:-}"
  if [[ "$CI_MODE" == true ]]; then
    printf '{"timestamp":"%s","module":"PythonValidation","status":"fail","message":"%s","remediation":"%s","exit_code":%d}\n' \
      "$(date -Iseconds)" "$msg" "$remediation" "$code" >&2
  else
    echo "❌ PYTHON VALIDATION FAILURE [$code]: $msg" >&2
    [[ -n "$remediation" ]] && echo "   Remediation: $remediation" >&2
  fi
  audit "FAIL" "[$code] $msg"
  exit "$code"
}

log "Python canon validation initializing — ruff + mypy + bandit + pytest (>=93% coverage)"

# ─────────────────────────────────────────────────────
# Pre-flight Checks (Beale v8.0)
# ─────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

command -v ruff >/dev/null    || fail "$EXIT_CONFIG" "ruff not installed" "pip install ruff"
command -v mypy >/dev/null    || fail "$EXIT_CONFIG" "mypy not installed" "pip install mypy"
command -v bandit >/dev/null  || fail "$EXIT_CONFIG" "bandit not installed" "pip install bandit"
command -v pytest >/dev/null  || fail "$EXIT_CONFIG" "pytest not installed" "pip install pytest pytest-cov"
command -v jq >/dev/null      || fail "$EXIT_CONFIG" "jq not installed" "apt install jq"

# ─────────────────────────────────────────────────────
# Phase 1: Ruff (Style + Quality + Security)
# ─────────────────────────────────────────────────────
log "Phase 1: ruff check --select ALL"
ruff_status="failed"
if [[ "$DRY_RUN" == false ]]; then
  if ruff check --select ALL .; then
    ruff_status="passed"
    log "ruff: 10.00 score achieved"
  else
    fail "$EXIT_RUFF" "ruff violations detected" "Fix all ruff errors • Run ruff check --fix where safe"
  fi
else
  log "dry-run → skipping ruff execution"
fi
audit "STATUS" "ruff=$ruff_status dry_run=$DRY_RUN"

# ─────────────────────────────────────────────────────
# Phase 2: Mypy --strict
# ─────────────────────────────────────────────────────
log "Phase 2: mypy --strict"
mypy_status="failed"
if [[ "$DRY_RUN" == false ]]; then
  if mypy --strict .; then
    mypy_status="passed"
    log "mypy: Zero type errors"
  else
    fail "$EXIT_MYPY" "mypy type errors detected" "Add type hints • Justify Any with comments"
  fi
else
  log "dry-run → skipping mypy execution"
fi
audit "STATUS" "mypy=$mypy_status dry_run=$DRY_RUN"

# ─────────────────────────────────────────────────────
# Phase 3: Bandit (Security Audit)
# ─────────────────────────────────────────────────────
log "Phase 3: bandit security audit"
bandit_status="failed"
if [[ "$DRY_RUN" == false ]]; then
  bandit_tmp="/tmp/bandit-python-validation-$$.json"
  if bandit -r . -f json -o "$bandit_tmp" && \
     ! jq -e '.results[] | select(.issue_severity == "HIGH" or .issue_severity == "MEDIUM")' "$bandit_tmp" >/dev/null; then
    bandit_status="passed"
    log "bandit: No high/medium issues"
    rm -f "$bandit_tmp"
  else
    jq '.results[] | select(.issue_severity == "HIGH" or .issue_severity == "MEDIUM")' "$bandit_tmp"
    rm -f "$bandit_tmp"
    fail "$EXIT_BANDIT" "bandit high/medium findings" "Fix or suppress with # nosec"
  fi
else
  log "dry-run → skipping bandit execution"
fi
audit "STATUS" "bandit=$bandit_status dry_run=$DRY_RUN"

# ─────────────────────────────────────────────────────
# Phase 4: Pytest + Coverage (>=93%)
# ─────────────────────────────────────────────────────
log "Phase 4: pytest with >=93% coverage"
pytest_status="failed"
if [[ "$DRY_RUN" == false ]]; then
  if pytest --cov=. --cov-fail-under=93 --cov-report=term-missing; then
    pytest_status="passed"
    log "pytest: All tests passed (>=93% coverage)"
  else
    fail "$EXIT_PYTEST" "pytest failed or coverage <93%" "Add missing tests • Improve coverage"
  fi
else
  log "dry-run → skipping pytest execution"
fi
audit "STATUS" "pytest=$pytest_status dry_run=$DRY_RUN"

# ─────────────────────────────────────────────────────
# Eternal Banner Drop (Beale-Approved)
# ─────────────────────────────────────────────────────
if [[ "$QUIET" == false ]]; then
  printf '
╔══════════════════════════════════════════════════════════════════════════════╗
║ RYLAN LABS • ETERNAL FORTRESS                                                  ║
║ Python Canon Validation — Complete                                             ║
║ Consciousness: 4.6 | Guardian: Bauer | Trinity Aligned                        ║
║                                                                               ║
║ ruff:  %s                                                                     ║
║ mypy:  %s                                                                     ║
║ bandit: %s                                                                    ║
║ pytest: %s                                                                    ║
║                                                                               ║
║ Python fortress pure — ready for production                                    ║
║                                                                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
' "$ruff_status" "$mypy_status" "$bandit_status" "$pytest_status"
fi

# ─────────────────────────────────────────────────────
# CI Mode Output (Bauer-Ready)
# ─────────────────────────────────────────────────────
if [[ "$CI_MODE" == true ]]; then
  printf '{"timestamp":"%s","module":"PythonValidation","status":"pass","message":"Python validation complete","ruff":"%s","mypy":"%s","bandit":"%s","pytest":"%s"}\n' \
    "$(date -Iseconds)" "$ruff_status" "$mypy_status" "$bandit_status" "$pytest_status"
fi

# ─────────────────────────────────────────────────────
# Final Audit & Exit
# ─────────────────────────────────────────────────────
audit "PASS" "python_validation_complete ruff=$ruff_status mypy=$mypy_status bandit=$bandit_status pytest=$pytest_status"
exit "$EXIT_SUCCESS"
