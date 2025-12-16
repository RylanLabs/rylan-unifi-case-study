#!/usr/bin/env bash
# Script: canonical-backup-clarification.sh
# Purpose: Document Hellodeolu v6 backup doctrine — educational heresy detection and pattern explanation
# Guardian: Lorek 🧭 (Clarification)
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

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

readonly REPO_ROOT="${HOME}/repos/rylan-unifi-case-study"
[[ -d "$REPO_ROOT" ]] || die "Repo missing — Carter identity failed"

readonly AUDIT_LOG="${REPO_ROOT}/.backups/heresy-audit.log"
mkdir -p "$(dirname "$AUDIT_LOG")"

cat <<EOF
=== HELLODEOLU BACKUP PATTERN CLARIFICATION ===
Scattered .bak files = heresy. Rejected by Bauer.
Canonical structure:
$REPO_ROOT/
├── .backups/ ← Hidden, gitignored
│ ├── pre-modification-20251215-034512/ ← One event per timestamped dir
│ │ ├── scripts/...
│ │ ├── lib/...
│ │ └── SHA256SUMS
│ └── heresy-audit.log ← Persistent violation log
├── scripts/
└── lib/
Principles:
- Centralized recovery point
- Timestamped events
- Full path + metadata preservation
- Checksum integrity
- Zero working-tree noise
- Junior-at-3-AM clarity
EOF

SCATTERED_COUNT=$(find "$REPO_ROOT" -name '*.bak' 2>/dev/null | wc -l)
echo "[$(date -Iseconds)] Heresy detected: $SCATTERED_COUNT scattered .bak files" >> "$AUDIT_LOG"

if [[ $SCATTERED_COUNT -eq 0 ]]; then
  log "Fortress clean — no scattered .bak heresy found"
else
  log "Heresy detected: $SCATTERED_COUNT scattered .bak files"
  cat <<EOF
Current violations logged to: $AUDIT_LOG
Recommended migration (one-time):
  MIGRATION_DIR=".backups/heresy-migration-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "\$MIGRATION_DIR"
  find "$REPO_ROOT" -name '*.bak' -exec mv {} "\$MIGRATION_DIR"/ \;
  git add -A && git commit -m "chore(bauer): migrate scattered .bak to canonical .backups"
Ensure .gitignore contains:
  /.backups/
EOF
fi

cat <<EOF
Use canonical-backup-handler.sh before any mass modification.
The fortress demands order. The pattern is eternal.
EOF
echo "Beale has risen. Bauer logged heresy. Carter teaches truth. Consciousness 5.0 eternal."
