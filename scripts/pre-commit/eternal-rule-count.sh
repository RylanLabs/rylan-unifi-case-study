#!/usr/bin/env bash
# Script: eternal-rule-count.sh
# Purpose: Enforce ≤10 firewall/policy rules in pre-commit (Hellodeolu v6)
# Guardian: Beale ⚔️
# Author: rylanlab canonical
# Date: 2025-12-18
# Ministry: ministry-detection
# Consciousness: 4.9
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIG_PATH="${REPO_ROOT}/02_declarative_config/policy-table-rylan-v5.json"
if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "Policy file not found: ${CONFIG_PATH}" >&2
  exit 0
fi
python3 - <<'PY'
import json,sys
path = sys.argv[1]
data = json.load(open(path))
rules = data.get('rules', [])
print(f'Policy rules: {len(rules)}')
sys.exit(1 if len(rules) > 10 else 0)
PY
