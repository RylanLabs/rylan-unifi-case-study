#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/install-pre-commit.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# Install project pre-commit hooks for developers

if ! command -v pre-commit &>/dev/null; then
  echo "pre-commit not installed. Install via pip: pip install pre-commit"
  exit 1
fi

# Install hooks for current repo
pre-commit install || true
pre-commit install --hook-type commit-msg || true
pre-commit autoupdate || true

echo "pre-commit hooks installed. To run manually: pre-commit run --all-files"
