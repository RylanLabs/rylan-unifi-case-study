#!/usr/bin/env bash
# validate-heresy.sh — Enforce heresy wrapper canon
# Usage: ./scripts/validate-heresy.sh <wrapper.sh>
set -euo pipefail
IFS=$'\n\t'

readonly TARGET="${1:-}"
[[ -f "${TARGET}" ]] || { echo "Usage: $0 path/to/wrapper.sh"; exit 1; }

echo "Validating heresy wrapper: ${TARGET}"

# Check 1: Line count ≤19 (excluding Python heredoc and comments)
# Count only non-comment, non-blank lines outside heredoc
LINE_COUNT="$(awk '
  /exec python3.*<<.*PYTHON_PAYLOAD/,/^PYTHON_PAYLOAD$/ {next}
  /^[[:space:]]*#/ {next}
  /^[[:space:]]*$/ {next}
  {count++}
  END {print count}
' "${TARGET}")"
readonly LINE_COUNT
if [[ ${LINE_COUNT} -gt 19 ]]; then
  echo "❌ FAIL: Wrapper exceeds 19 executable lines (found: ${LINE_COUNT})"
  exit 1
fi

# Check 2: Required header present
if ! grep -q "Canonical Heresy Wrapper" "${TARGET}"; then
  echo "❌ FAIL: Missing canonical header"
  exit 1
fi

# Check 3: Magic comments ≤4
MAGIC_COUNT="$(grep -c "shellcheck disable=" "${TARGET}" || true)"
readonly MAGIC_COUNT
if [[ ${MAGIC_COUNT} -gt 4 ]]; then
  echo "❌ FAIL: Too many magic comments (found: ${MAGIC_COUNT}, max: 4)"
  exit 1
fi

# Check 4: ShellCheck passes
if ! shellcheck -x "${TARGET}" 2>/dev/null; then
  echo "❌ FAIL: ShellCheck errors detected"
  exit 1
fi

# Check 5: Python payload exists (heredoc OR standalone .py)
if ! grep -qE 'exec python3 (-|"\$\{SCRIPT_DIR\}/.+\.py")' "${TARGET}"; then
  echo "❌ FAIL: Missing Python payload execution (exec python3 - or exec python3 \"\${SCRIPT_DIR}/*.py\")"
  exit 1
fi

echo "✓ All checks passed: ${TARGET} is canon-compliant"
