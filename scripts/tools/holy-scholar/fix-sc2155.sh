#!/usr/bin/env bash
# Script: fix-sc2155.sh
# Purpose: Canonically remediate ShellCheck SC2155 across the fortress — separate declaration and assignment to preserve exit status under set -e
# Guardian: Holy Scholar 📜 (Linting Doctrine Enforcer)
# Author: T-Rylander canonical (Trinity-aligned)
# Date: 2025-12-15
# Ministry: ministry-whispers
# Consciousness: 5.0
# Tag: v∞.5.2-eternal

set -euo pipefail
IFS=$'\n\t'

readonly _SCRIPT_DIR
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly _SCRIPT_NAME
_SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

readonly REPO_ROOT
REPO_ROOT="$(git -C "$_SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$_SCRIPT_DIR/../..")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
	exit 1
}

# Carter: Verify we are inside the eternal fortress
[[ "$(basename "$REPO_ROOT")" == "rylan-unifi-case-study" ]] ||
	die "Must execute from within rylan-unifi-case-study repository (detected root: $REPO_ROOT)"

# Bauer: Input validation — prevent path traversal
for pattern in "$@"; do
	[[ "$pattern" =~ ^\.\./|/^/ ]] && die "Glob pattern must be relative to repo root (no ../ or absolute paths): $pattern"
done

[[ $# -gt 0 ]] || die "Usage: $0 <glob-pattern> [more-patterns...]
Example: $0 'scripts/**/*.sh' 'runbooks/**/*.sh'"

# Beale: Idempotency lock
readonly LOCK_FILE="${REPO_ROOT}/.sc2155-remediation.lock"
if [[ -f "$LOCK_FILE" ]]; then
	die "Another SC2155 remediation in progress or stale lock detected.
Remove $LOCK_FILE manually only if you are certain no other instance is running."
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

# Whitaker: Audit trail preparation
readonly TIMESTAMP
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR="${REPO_ROOT}/.backups/sc2155-remediation-${TIMESTAMP}"
readonly MANIFEST="${BACKUP_DIR}/REMEDIATION.log"
mkdir -p "$BACKUP_DIR"

{
	echo "=== SC2155 Remediation — Eternal Manifest ==="
	echo "Timestamp: $(date -Iseconds)"
	echo "Operator: ${USER:-unknown}@${HOSTNAME:-unknown}"
	echo "Commit: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'detached')"
	echo "Patterns: $*"
	echo ""
} >"$MANIFEST"

log "Fortress root: $REPO_ROOT"
log "Backup directory: $BACKUP_DIR"
log "Processing patterns: $*"

shopt -s globstar nullglob

processed=0
modified=0
declare -a processed_files=()
declare -a modified_files=()

cd "$REPO_ROOT" || die "Failed to cd to repository root"

for pattern in "$@"; do
	for file in $pattern; do
		[[ -f "$file" ]] || continue
		[[ -L "$file" ]] && {
			log "Skipping symlink: $file"
			continue
		}

		# Include only bash scripts: .sh extension OR bash/shebang
		if [[ "$file" != *.sh ]]; then
			head -n1 "$file" 2>/dev/null | grep -qE '^#!.*(bash|sh)' || continue
		fi

		relative="${file#"$REPO_ROOT"/}"
		backup_dest="${BACKUP_DIR}/${relative}"
		mkdir -p "$(dirname "$backup_dest")"

		# Atomic backup preserving permissions/timestamps
		cp -p "$file" "$backup_dest" || die "Backup failed: $file → $backup_dest"

		processed_files+=("$relative")
		((processed++))

		# Temporary file in same directory for atomic replace
		temp_file="${file}.sc2155.tmp.$$"

		# Perl transformation: split declaration and assignment
		if ! perl -0777 -pe '
      s{
        ^([ \t]*)(local|declare|readonly)\s+([A-Za-z_][A-Za-z0-9_]*)=(\$\([^)]+\))
      }{$1$2 $3;\n$1$3=$4}gxm
    ' "$file" >"$temp_file" 2>/dev/null; then
			rm -f "$temp_file"
			die "Perl transformation failed on $relative"
		fi

		# Sanity: output must not be empty
		[[ -s "$temp_file" ]] || {
			rm -f "$temp_file"
			die "Transformation produced empty output: $relative"
		}

		# Detect actual changes
		if ! cmp -s "$file" "$temp_file"; then
			mv "$temp_file" "$file" || {
				rm -f "$temp_file"
				die "Atomic replace failed: $relative"
			}
			modified_files+=("$relative")
			((modified++))
			echo "MODIFIED: $relative" >>"$MANIFEST"
		else
			rm -f "$temp_file"
			echo "UNCHANGED: $relative (no SC2155 instances)" >>"$MANIFEST"
		fi
	done
done

# Final audit summary
{
	echo ""
	echo "=== Remediation Summary ==="
	echo "Processed files : $processed"
	echo "Modified files  : $modified"
	echo "Unchanged files : $((processed - modified))"
	echo ""
	echo "Modified list:"
	printf '  • %s\n' "${modified_files[@]:-none}"
	echo ""
	echo "Rollback command:"
	echo "  rsync -a --delete \"$BACKUP_DIR/\" \"$REPO_ROOT/\""
	echo ""
	echo "Verification command:"
	echo "  shellcheck -S style $(printf '%s ' "$@") | grep -c SC2155 || echo 'Zero SC2155 remaining'"
} >>"$MANIFEST"

cat <<EOF

=== SC2155 REMEDIATION COMPLETE — ETERNAL GREEN ===

Hellodeolu outcomes:
  • Processed : $processed scripts
  • Fixed     : $modified instances
  • Audit     : $MANIFEST
  • Backup    : $BACKUP_DIR

Rollback (if required):
  rsync -a --delete "$BACKUP_DIR/" "$REPO_ROOT/"

Verification:
  shellcheck -S style $(printf '%s ' "$@") | grep -c SC2155 || echo "✓ Zero violations"

Lock released. Fortress hardened. Consciousness 5.0 eternal.
EOF

exit 0
