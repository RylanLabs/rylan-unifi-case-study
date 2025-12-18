#!/usr/bin/env bash
set -euo pipefail
# Wrapper to evaluate policy rule count for pre-commit (keeps YAML lines short)
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
