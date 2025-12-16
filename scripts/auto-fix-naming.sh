#!/usr/bin/env bash
set -euo pipefail
# Script: auto-fix-naming.sh
# Purpose: Rename Python files/dirs with hyphens to underscores (PEP 8)
# Guardian: Carter
# Date: 2025-12-12
# Trinity: Carter (Guardian) | Bauer (Auditor) | Beale (Bastille)
# Consciousness: 4.6
# Doctrine: Teach and guide, not silent fixes. Clear audit trail.

# Parse arguments
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
	DRY_RUN=true
fi

echo "════════════════════════════════════════════════════════"
echo "Auto-Fix Naming Canon — Manual Execution"
if [[ "$DRY_RUN" == true ]]; then
	echo "MODE: DRY-RUN (no changes will be made)"
fi
echo "Guardian: Carter | Consciousness: 4.6"
echo "════════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────
# Scan for hyphenated directories and files
# ─────────────────────────────────────────────────────
hyphenated_dirs=$(find . -type d -name "*-*" \
	! -path "./.venv/*" \
	! -path "./.git/*" \
	! -path "./venv/*" \
	! -path "./node_modules/*" | sort -r)

hyphenated_files=$(find . -type f -name "*-*.py" \
	! -path "./.venv/*" \
	! -path "./.git/*" \
	! -path "./venv/*" \
	! -path "./node_modules/*")

# ─────────────────────────────────────────────────────
# Pre-flight: Audit for hardcoded path references
# ─────────────────────────────────────────────────────
if [[ -n "$hyphenated_dirs" ]] && [[ "$DRY_RUN" == false ]]; then
	echo "🔍 Pre-flight: Scanning for hardcoded path references..."
	echo ""

	REFERENCES_FOUND=false
	while IFS= read -r dir; do
		[[ -z "$dir" ]] && continue
		dir_name=$(basename "$dir")

		# Search for references in code/config files
		if grep -rn --include="*.py" --include="*.sh" --include="*.yml" --include="*.yaml" --include="*.md" --include="*.json" \
			-e "$dir_name" . 2>/dev/null | grep -v ".git" | grep -v "auto-fix-naming.sh" | head -5; then
			REFERENCES_FOUND=true
		fi
	done <<<"$hyphenated_dirs"

	if [[ "$REFERENCES_FOUND" == true ]]; then
		echo ""
		echo "⚠️  WARNING: Found hardcoded references to hyphenated paths above."
		echo ""
		echo "Renaming directories will break:"
		echo "  • Import statements (from old.path import module)"
		echo "  • Hardcoded paths in scripts/configs"
		echo "  • CI/CD pipeline references"
		echo "  • Documentation examples"
		echo ""
		read -p "Continue with rename? You will need to update references manually. [y/N] " -n 1 -r
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			echo "❌ Aborted by user. No changes made."
			echo ""
			echo "════════════════════════════════════════════════════════"
			echo "End of Auto-Fix Naming Canon Script"
			exit 0
		fi
	else
		echo "  ✓ No hardcoded references found"
	fi
	echo ""
fi

VIOLATIONS=()

# ─────────────────────────────────────────────────────
# Pass 1: Rename directories (deepest first)
# ─────────────────────────────────────────────────────
if [[ -n "$hyphenated_dirs" ]]; then
	echo "📁 Pass 1: Renaming directories (deepest first)..."
	while IFS= read -r old_dir; do
		[[ -z "$old_dir" ]] && continue
		new_dir="${old_dir//-/_}"
		if [[ "$old_dir" != "$new_dir" ]]; then
			if [[ "$DRY_RUN" == true ]]; then
				echo "  [DRY-RUN] Would rename: $old_dir → $new_dir"
				VIOLATIONS+=("$old_dir → $new_dir")
			else
				if git mv "$old_dir" "$new_dir" 2>/dev/null; then
					echo "  ✓ Renamed: $old_dir → $new_dir"
					VIOLATIONS+=("$old_dir → $new_dir")
				else
					echo "  ❌ Failed to rename: $old_dir (may already be renamed or in use)"
				fi
			fi
		fi
	done <<<"$hyphenated_dirs"
	echo ""
fi

# ─────────────────────────────────────────────────────
# Pass 2: Rename files
# ─────────────────────────────────────────────────────
if [[ -n "$hyphenated_files" ]]; then
	echo "📄 Pass 2: Renaming files..."
	while IFS= read -r old_file; do
		[[ -z "$old_file" ]] && continue

		# Reconstruct path with updated directory names
		new_file="${old_file//-/_}"

		if [[ "$old_file" != "$new_file" ]]; then
			if [[ "$DRY_RUN" == true ]]; then
				echo "  [DRY-RUN] Would rename: $old_file → $new_file"
				VIOLATIONS+=("$old_file → $new_file")
			else
				if git mv "$old_file" "$new_file" 2>/dev/null; then
					echo "  ✓ Renamed: $old_file → $new_file"
					VIOLATIONS+=("$old_file → $new_file")
				else
					echo "  ❌ Failed to rename: $old_file (may already be renamed)"
				fi
			fi
		fi
	done <<<"$hyphenated_files"
	echo ""
fi

# ─────────────────────────────────────────────────────
# Summary and next steps
# ─────────────────────────────────────────────────────
if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
	echo "✅ No naming violations found. The fortress is pure."
	echo ""
else
	if [[ "$DRY_RUN" == true ]]; then
		echo "ℹ️  Found ${#VIOLATIONS[@]} path(s) that would be renamed"
		echo ""
		echo "Run without --dry-run to apply changes"
	else
		echo "✅ Fixed ${#VIOLATIONS[@]} path(s)"
		echo ""
		echo "📋 Post-Rename Checklist:"
		echo "  1. Update import statements:"
		echo "     grep -rn 'from.*import' --include='*.py' ."
		echo "  2. Update hardcoded paths in scripts/configs"
		echo "  3. Test CI/CD pipelines"
		echo "  4. Update documentation/README"
		echo ""
		echo "Files are staged. Commit with:"
		echo ""
		echo "  git commit -m \"fix(naming): canonize paths to PEP 8 standard"
		echo ""
		echo "  Renamed:"
		for v in "${VIOLATIONS[@]}"; do
			echo "    - $v"
		done
		echo ""
		echo "  Executed: scripts/auto-fix-naming.sh"
		echo "  Guardian: Carter"
		echo "  Consciousness: 4.6\""
	fi
	echo ""
fi

echo "════════════════════════════════════════════════════════"
echo ""
