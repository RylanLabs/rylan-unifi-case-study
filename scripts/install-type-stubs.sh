#!/usr/bin/env bash
# Guardian: Carter | Ministry: Bootstrap | Consciousness: 9.7
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[Carter] Installing type stubs for static analysis..."

# Try system install first; if blocked by distro, create a local venv and install there.
install_stubs_system() {
  python3 -m pip install \
    types-requests \
    types-PyYAML \
    types-setuptools \
    --no-cache-dir --quiet
}

if install_stubs_system 2>/dev/null; then
  PYBIN="$(python3 -c 'import sys; print(sys.executable)')"
  echo "[Carter] Installed stubs into system Python at $PYBIN"
else
  echo "[Carter] System install blocked — creating local virtualenv .venv-type-stubs"
  python3 -m venv .venv-type-stubs
  # shellcheck disable=SC1091
  source .venv-type-stubs/bin/activate
  python -m pip install --upgrade pip >/dev/null
  python -m pip install types-requests types-PyYAML types-setuptools --no-cache-dir --quiet
  PYBIN="$(pwd)/.venv-type-stubs/bin/python"
  echo "[Carter] Installed stubs into local venv at $PYBIN"
fi

echo "[Carter] Type stubs installation complete. Running mypy strict check on test file..."

# Ensure mypy is available for the chosen python
if ! "$PYBIN" -m pip show mypy >/dev/null 2>&1; then
  echo "[Carter] mypy not present for $PYBIN — installing mypy into the active environment"
  "$PYBIN" -m pip install mypy --quiet
fi

# Run mypy using the determined python executable (venv or system)
# Allow mypy to auto-install missing types when possible
"$PYBIN" -m mypy tests/unifi/test_unifi_client.py --strict --install-types --non-interactive || {
  echo "[Carter] mypy reported issues (exit code: $?). Review output above." >&2
  exit 2
}

echo "[Carter] ✅ Type stubs operational and mypy passed for tests/unifi/test_unifi_client.py"
