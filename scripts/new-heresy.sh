#!/usr/bin/env bash
# new-heresy.sh — One-command heresy wrapper creator
# Usage: ./scripts/new-heresy.sh runbooks/ministry-ai/new-tool.sh
set -euo pipefail
IFS=$'\n\t'

readonly TEMPLATE="templates/heresy-wrapper.sh"
readonly TARGET="${1:-}"

[[ -f "${TEMPLATE}" ]] || { echo "ERROR: Run from repo root"; exit 1; }
[[ -n "${TARGET}" ]] || {
  echo "Usage: $0 path/to/new-wrapper.sh"
  echo "Example: $0 runbooks/ministry-carter/adopt-flex-mini.sh"
  exit 1
}

# Create target directory if needed
mkdir -p "$(dirname "${TARGET}")"

# Copy template
cp "${TEMPLATE}" "${TARGET}"
chmod +x "${TARGET}"

# Generate commit message
TOOL_NAME="$(basename "${TARGET}" .sh)"
readonly TOOL_NAME
cat <<EOF

✓ Created: ${TARGET}

Next steps:
1. Edit the 4 PLACEHOLDER lines in ${TARGET}
2. Add your Python payload (100-400 lines, mypy --strict)
3. Validate: ./scripts/validate-bash.sh ${TARGET}
4. Commit with:

   git add ${TARGET}
   git commit -m "feat(heresy): add ${TOOL_NAME} wrapper

   - Whitaker justification: <offensive/defensive reason>
   - Trinity alignment: <Carter|Bauer|Beale>
   - Heresy #<1-4>: <brief description>
   
   Refs: INSTRUCTION-SET-ETERNAL-v3.2"

EOF
