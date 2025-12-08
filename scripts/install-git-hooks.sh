#!/usr/bin/env bash
set -euo pipefail

# Install versioned git hooks by setting core.hooksPath to .githooks
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

if [[ ! -d ".githooks" ]]; then
  echo "No .githooks directory found. Nothing to install." >&2
  exit 1
fi

git config core.hooksPath .githooks

echo "Installed git hooks: core.hooksPath set to .githooks"

echo "You may need to make hook executable: chmod +x .githooks/*"
