#!/usr/bin/env bash
# Script: audit-shellcheck-violations.sh
# Purpose: Catalog SC2034/SC2155 violations across fortress — generate structured report for remediation
# Author: T-Rylander canonical (Leo glue internalized)
# Date: 2025-12-15
# Guardian: Bauer 🛡️ (Verification Ministry)
# Ministry: ministry-whispers
# Tag: v∞.3.2-eternal
# Consciousness: 5.0 — truth through subtraction + audit clarity

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
readonly REPO_ROOT

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
	exit 1
}

[[ "$(basename "$REPO_ROOT")" == "rylan-unifi-case-study" ]] ||
	die "Must execute from within rylan-unifi-case-study repository"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly TIMESTAMP
REPORT_DIR="${REPO_ROOT}/.backups/shellcheck-audit-${TIMESTAMP}"
readonly REPORT_DIR
MANIFEST="${REPORT_DIR}/VIOLATIONS.md"
readonly MANIFEST
mkdir -p "$REPORT_DIR"

{
	echo "# ShellCheck SC2034/SC2155 Audit Report"
	echo "**Generated:** $(date -Iseconds)"
	echo "**Operator:** ${USER:-unknown}@${HOSTNAME:-unknown}"
	echo "**Commit:** $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'detached')"
	echo ""
	echo "## Summary"
	echo ""
} >"$MANIFEST"

log "Scanning fortress for SC2034/SC2155 violations..."

shopt -s globstar nullglob
declare -a shell_files=()

for pattern in "$REPO_ROOT"/{scripts,01_bootstrap,runbooks}/**/*.sh "$REPO_ROOT"/*.sh; do
	[[ -f "$pattern" && ! -L "$pattern" ]] && shell_files+=("$pattern")
done

log "Identified ${#shell_files[@]} candidate shell scripts"

sc2034_count=0
sc2155_count=0
declare -A sc2034_files sc2155_files

for file in "${shell_files[@]}"; do
	relative="${file#"$REPO_ROOT"/}"
	violations=$(shellcheck -f gcc "$file" 2>/dev/null | grep -E "SC2034|SC2155" || true)
	[[ -z "$violations" ]] && continue

	sc2034=$(echo "$violations" | grep -c "SC2034" || true)
	sc2155=$(echo "$violations" | grep -c "SC2155" || true)

	((sc2034 > 0)) && {
		sc2034_files["$relative"]=$sc2034
		((sc2034_count += sc2034))
	}
	((sc2155 > 0)) && {
		sc2155_files["$relative"]=$sc2155
		((sc2155_count += sc2155))
	}

	echo "$violations" >"${REPORT_DIR}/${relative//\//_}.log"
done

{
	echo "| Violation | Total Count | Affected Files |"
	echo "|-----------|-------------|----------------|"
	echo "| SC2034 (unused variables) | $sc2034_count | ${#sc2034_files[@]} |"
	echo "| SC2155 (masked exit codes) | $sc2155_count | ${#sc2155_files[@]} |"
	echo ""
	echo "## SC2034 Violations"
	for file in "${!sc2034_files[@]}"; do echo "- \`$file\` (${sc2034_files[$file]})"; done
	echo ""
	echo "## SC2155 Violations"
	for file in "${!sc2155_files[@]}"; do echo "- \`$file\` (${sc2155_files[$file]})"; done
	echo ""
	echo "## Remediation Commands"
	echo "\`\`\`bash"
	echo "./scripts/tools/holy-scholar/fix-sc2155.sh 'scripts/**/*.sh' '01_bootstrap/**/*.sh' 'runbooks/**/*.sh'"
	echo "./scripts/tools/bauer/fix-sc2034.sh 'scripts/**/*.sh' '01_bootstrap/**/*.sh' 'runbooks/**/*.sh'"
	echo "./scripts/tools/gatekeeper/remediate-shellcheck.sh"
	echo "\`\`\`"
} >>"$MANIFEST"

log "Audit complete — report: $MANIFEST"
cat "$MANIFEST"
