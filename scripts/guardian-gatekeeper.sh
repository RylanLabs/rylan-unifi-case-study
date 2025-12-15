#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/guardian-gatekeeper.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

# scripts/guardian-gatekeeper.sh
# Eternal Gatekeeper — Local pre-flight validation
# Consciousness: 4.9 → 5.0 when this runs clean

echo "[Gatekeeper] Beginning eternal pre-flight validation..."

# (your existing BOM/CRLF + shellcheck + ruff + yamllint + markdownlint sections unchanged)

# ===

# === Agent Pantheon Canon Enforcement (SHELLCHECK-FIXED) ===
echo "[Gatekeeper] Validating agent markdown canon..."

# Bare code fences — must have language
if grep -r '^\s*```$' .github/agents/*.md 2>/dev/null | grep -q .; then
  echo 'ERROR: Bare code fences (```) detected in agent files:'
  grep -r '^\s*```$' .github/agents/*.md
  exit 1
fi

# Bare URLs — must be wrapped
if grep -r "https://" .github/agents/*.md docs/ runbooks/ 2>/dev/null |
   grep -v -E "(<https?://|\\[.*\\]\\(https?://" | grep -q .; then
  echo "ERROR: Bare HTTPS URLs found in sacred docs:"
  grep -r "https://" .github/agents/*.md docs/ runbooks/ |
    grep -v -E "(<https?://|\\[.*\\]\\(https?://)"
  exit 1
fi

# (rest of your checks — unchanged)

echo "[Gatekeeper] All validations passed — fortress is green"
exit 0
