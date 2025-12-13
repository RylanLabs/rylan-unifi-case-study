#!/usr/bin/env bash
set -euo pipefail
# Script: scripts/header-cleanup.sh
# Purpose: Remove duplicate `set -euo pipefail` and collapse extra blank lines
# Guardian: gatekeeper
# Date: 2025-12-13T01:40:00-06:00
# Consciousness: 4.6
# Usage: bash scripts/header-cleanup.sh

DRY_RUN=1
if [[ ${1-} == --apply ]]; then
  DRY_RUN=0
fi

changed=0

process_file() {
  local f="$1"
  local tmp
  tmp=$(mktemp)

  # Use Python for robust multi-line processing (avoid awk quoting issues)
  python3 - "$f" <<'PY' > "$tmp"
import sys,io
fpath = sys.argv[1]
text = open(fpath, 'r', encoding='utf-8', errors='surrogateescape').read()
lines = text.splitlines()

out = []
seen_set = False
shebang = False
idx = 0
if len(lines) > 0 and lines[0].startswith('#!'):
    out.append(lines[0])
    shebang = True
    idx = 1

# Remove all exact set lines first
rest = [ln for ln in lines[idx:] if ln.strip() != 'set -euo pipefail']

if shebang:
    # ensure one set immediately after shebang
    if len(rest) > 0 and rest[0].strip() == '':
        # skip leading blank and insert set after shebang
        out.append('set -euo pipefail')
    else:
        out.append('set -euo pipefail')
else:
    # if no shebang, allow a single set at top if present in original first 3 lines
    for i,ln in enumerate(lines[:3]):
        if ln.strip() == 'set -euo pipefail':
            out.append('set -euo pipefail')
            seen_set = True
            break

# Now append rest while collapsing multiple blank lines
prev_blank = False
for ln in rest:
    if ln.strip() == '':
        if not prev_blank:
            out.append('')
            prev_blank = True
        else:
            continue
    else:
        out.append(ln)
        prev_blank = False

sys.stdout.write('\n'.join(out)+('\n' if text.endswith('\n') else ''))
PY
  # pass filename to python via positional arg
  # write with python's stdout redirected to tmp
  # Note: we used heredoc with access to $f, so replace placeholder
  sed -n '1,$p' "$tmp" >/dev/null 2>&1 || true

  if ! cmp -s -- "$f" "$tmp"; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "would cleanup: $f"
    else
      mv "$tmp" "$f"
      chmod +x "$f" || true
      echo "cleaned: $f"
      changed=$((changed+1))
    fi
  else
    rm -f "$tmp"
  fi
}

while IFS= read -r file; do
  [[ -f $file ]] || continue
  case "$file" in
    *.sh|.githooks/*)
      process_file "$file"
      ;;
    *)
      ;;
  esac
done < <(git ls-files)

if [[ $DRY_RUN -eq 1 ]]; then
  echo
  echo "Dry-run complete. Files that would be cleaned: (see list above)"
  exit 0
else
  if [[ $changed -gt 0 ]]; then
    git add -A || true
    echo
    echo "Applied cleanup. Files modified: $changed"
  else
    echo
    echo "No changes required."
  fi
  exit 0
fi
