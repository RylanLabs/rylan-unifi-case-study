#!/usr/bin/env bash
# validate-heresy.sh — Enforce heresy wrapper canon
# Usage: ./scripts/validate-heresy.sh <wrapper.sh>
set -euo pipefail

readonly TARGET="${1:-}"
[[ -f "${TARGET}" ]] || { echo "Usage: $0 path/to/wrapper.sh"; exit 1; }

echo "Validating heresy wrapper: ${TARGET}"

# Check 1: Line count ≤19 (excluding Python payload)
readonly LINE_COUNT=$(grep -v '^PYTHON_PAYLOAD$' "${TARGET}" | grep -v '^PY$' | wc -l)
if [[ ${LINE_COUNT} -gt 19 ]]; then
  echo "❌ FAIL: Wrapper exceeds 19 lines (found: ${LINE_COUNT})"
  exit 1
fi

# Check 2: Required header present
if ! grep -q "Canonical Heresy Wrapper" "${TARGET}"; then
  echo "❌ FAIL: Missing canonical header"
  exit 1
fi

# Check 3: Magic comments ≤4
readonly MAGIC_COUNT=$(grep -c "shellcheck disable=" "${TARGET}" || true)
if [[ ${MAGIC_COUNT} -gt 4 ]]; then
  echo "❌ FAIL: Too many magic comments (found: ${MAGIC_COUNT}, max: 4)"
  exit 1
fi

# Check 4: ShellCheck passes
if ! shellcheck -x "${TARGET}" 2>/dev/null; then
  echo "❌ FAIL: ShellCheck errors detected"
  exit 1
fi

# Check 5: Python payload exists
if ! grep -q "exec python3 -" "${TARGET}"; then
  echo "❌ FAIL: Missing Python payload execution"
  exit 1
fi

echo "✓ All checks passed: ${TARGET} is canon-compliant"
