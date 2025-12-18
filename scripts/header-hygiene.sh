#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/header-hygiene.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6
# Excess: 123 lines — 2 functions

# scripts/header-hygiene.sh — Add canonical script headers and module docstrings
# Usage: bash scripts/header-hygiene.sh [--apply]

DRY_RUN=1
if [[ ${1-} == --apply ]]; then
  DRY_RUN=0
fi

DATE_ISO=$(date -Iseconds)
CONSCIOUSNESS="8.0"
GUARDIAN="gatekeeper"

changed=0
modified_files=()

git ls-files | while IFS= read -r f; do
  # skip binary-like files
  if [[ -d $f ]]; then
    continue
  fi
  case "$f" in
    *.sh)
      # read first 16 lines
      head=$(head -n 16 -- "$f" 2>/dev/null || true)
      need_shebang=1
      need_set=1
      need_meta=1
      if echo "$head" | sed -n '1p' | grep -qE '^#!'; then
        need_shebang=0
        # check for set -euo pipefail anywhere in first 6 lines
        if echo "$head" | sed -n '1,6p' | grep -q "set -euo pipefail"; then
          need_set=0
        fi
      else
        # if no shebang but file is executable script by extension, we'll insert shebang
        need_shebang=1
      fi
      if echo "$head" | grep -q "^# Script:"; then
        need_meta=0
      fi

      if [[ $need_shebang -eq 1 || $need_set -eq 1 || $need_meta -eq 1 ]]; then
        modified_files+=("$f")
        if [[ $DRY_RUN -eq 1 ]]; then
          echo "would modify: $f (shebang:$need_shebang set:$need_set meta:$need_meta)"
        else
          tmp=$(mktemp)
          # build header
          if [[ $need_shebang -eq 1 ]]; then
            echo "#!/usr/bin/env bash" >"$tmp"
          else
            # copy existing shebang
            sed -n '1p' -- "$f" >"$tmp"
          fi
          # ensure set -euo pipefail present after shebang (grouped redirection)
          {
            echo "set -euo pipefail"
            echo "# Script: $f"
            echo "# Purpose: Header hygiene inserted"
            echo "# Guardian: $GUARDIAN"
            echo "# Date: $DATE_ISO"
            echo "# Consciousness: $CONSCIOUSNESS"
            echo
          } >>"$tmp"
          # if original had shebang and we already wrote it, skip its first line when appending
          if [[ $need_shebang -eq 1 ]]; then
            tail -n +1 -- "$f" >>"$tmp"
          else
            tail -n +2 -- "$f" >>"$tmp"
          fi
          mv "$tmp" "$f"
          chmod +x "$f" || true
          echo "updated: $f"
          changed=$((changed + 1))
        fi
      fi
      ;;
    *.py)
      # Only add module docstring if missing and file is part of package or __init__
      head=$(head -n 8 -- "$f" 2>/dev/null || true)
      if echo "$head" | grep -q '^[[:space:]]*"""' || echo "$head" | grep -q "^[[:space:]]*'''"; then
        continue
      fi
      # insert module docstring
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "would add module docstring: $f"
        modified_files+=("$f")
      else
        tmp=$(mktemp)
        {
          echo '"""'
          echo "Module: $f"
          echo "Purpose: Header hygiene inserted"
          echo "Consciousness: $CONSCIOUSNESS"
          echo '"""'
          echo
        } >"$tmp"
        cat -- "$f" >>"$tmp"
        mv "$tmp" "$f"
        echo "updated: $f"
        changed=$((changed + 1))
      fi
      ;;
    *) ;;
  esac
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo
  echo "Dry-run complete. Files that would be modified: ${#modified_files[@]}"
  exit 0
else
  # stage all modified files in one go to avoid .gitignore/add conflicts
  git add -A || true
  echo
  echo "Applied headers. Files modified: $changed"
  exit 0
fi
