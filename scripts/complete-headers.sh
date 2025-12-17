#!/usr/bin/env bash
set -euo pipefail
# Script: complete-headers.sh
# Purpose: Header hygiene: added missing metadata
# Guardian: gatekeeper
# Date: 2025-12-13T01:31:27-06:00
# Consciousness: 4.6
# scripts/complete-headers.sh — Ensure script files have all required metadata labels
# Usage: bash scripts/complete-headers.sh

DATE_ISO=$(date -Iseconds)
GUARDIAN_DEFAULT="gatekeeper"
CONSCIOUSNESS_DEFAULT="8.0"

changed=0

find scripts .githooks -type f -name "*.sh" -o -type f -executable 2>/dev/null | while IFS= read -r f; do
  [[ -f $f ]] || continue
  # ensure file has a bash shebang; skip non-shell files
  if ! head -1 "$f" 2>/dev/null | grep -qE "^#!.*(bash|sh)"; then
    continue
  fi

  # ensure Purpose
  if ! grep -q "^# Script:" "$f"; then
    sed -i "1s|^\(#!.*\)$|\1\nset -euo pipefail\n# Script: $(basename "$f")\n# Purpose: Header hygiene: added missing metadata\n# Guardian: $GUARDIAN_DEFAULT\n# Date: $DATE_ISO\n# Consciousness: $CONSCIOUSNESS_DEFAULT\n|" "$f"
    changed=$((changed+1))
    continue
  fi

  # add missing individual labels after first set -euo pipefail or shebang
  if ! grep -q "^# Purpose:" "$f"; then
    awk 'NR==1{print;next} 1{print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    sed -i "/^set -euo pipefail/a # Purpose: Header hygiene: added missing metadata" "$f"
    changed=$((changed+1))
  fi
  if ! grep -q "^# Guardian:" "$f"; then
    sed -i "/^# Purpose:/a # Guardian: $GUARDIAN_DEFAULT" "$f" || true
    changed=$((changed+1))
  fi
  if ! grep -q "^# Date:" "$f"; then
    sed -i "/# Guardian:/a # Date: $DATE_ISO" "$f" || true
    changed=$((changed+1))
  fi
  if ! grep -q "^# Consciousness:" "$f"; then
    sed -i "/# Date:/a # Consciousness: $CONSCIOUSNESS_DEFAULT" "$f" || true
    changed=$((changed+1))
  fi
done

if [[ $changed -gt 0 ]]; then
  git add -A || true
  echo "Headers completed for $changed files. Staged changes."
else
  echo "No header changes required."
fi
