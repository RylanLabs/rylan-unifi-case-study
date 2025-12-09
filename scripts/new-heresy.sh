#!/usr/bin/env bash
# scripts/new-heresy.sh — Generator for Canonical Heresy Wrappers
set -euo pipefail; IFS=$'\n\t'

[[ $# -eq 1 ]] || { echo "Usage: $0 <path/to/new-script.sh>"; exit 1; }
TARGET="$1"; TEMPLATE="templates/heresy-wrapper.sh"

[[ -f "$TEMPLATE" ]] || { echo "ERROR: Template not found"; exit 1; }
[[ ! -f "$TARGET" ]] || { echo "ERROR: Target exists"; exit 1; }

mkdir -p "$(dirname "$TARGET")"
cp "$TEMPLATE" "$TARGET"
chmod +x "$TARGET"

echo "✅ Created: $TARGET"
echo "📋 Commit Template:"
echo "feat(heresy): add <name> – permitted heresy #<1-4>"
echo ""
echo "- Implements <description>"
echo "- Wraps Python payload (lines 20+)"
echo "- Validated via ./scripts/validate-python.sh"
