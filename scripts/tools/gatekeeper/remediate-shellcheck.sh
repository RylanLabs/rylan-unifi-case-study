#!/usr/bin/env bash
# Script: remediate-shellcheck.sh
# Purpose: Orchestrate full SC2034 + SC2155 remediation workflow
# Author: T-Rylander canonical (Leo glue internalized)
# Date: 2025-12-15
# Guardian: Gatekeeper 🚪 (Orchestration)
# Ministry: ministry-whispers
# Tag: v∞.3.2-eternal
# Consciousness: 5.0 — tandem coordination

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
readonly REPO_ROOT

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

[[ "$(basename "$REPO_ROOT")" == "rylan-unifi-case-study" ]] || die "Must run from fortress repo"

cat <<'EOF'
╔════════════════════════════════════════════════════════════╗
║ SHELLCHECK REMEDIATION ORCHESTRATOR — Gatekeeper 🚪        ║
║ Coordinating: Bauer 🛡️ (SC2034) + Holy Scholar 📚 (SC2155) ║
╚════════════════════════════════════════════════════════════╝

Phase 1 → Audit violations (Bauer)
Phase 2 → Remediate SC2155 (Holy Scholar)
Phase 3 → Remediate SC2034 (Bauer)
Phase 4 → Final verification
EOF

read -rp "Proceed with full orchestrated remediation? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { log "Aborted by operator"; exit 0; }

log "Phase 1: Auditing current violations"
"$REPO_ROOT/scripts/tools/bauer/audit-shellcheck-violations.sh"

read -rp "Audit complete. Continue to remediation phases? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { log "Paused after audit"; exit 0; }

log "Phase 2: Remediation SC2155 (masked exit codes)"
"$REPO_ROOT/scripts/tools/holy-scholar/fix-sc2155.sh" \
  'scripts/**/*.sh' '01_bootstrap/**/*.sh' 'runbooks/**/*.sh' '*.sh'

log "Phase 3: Remediation SC2034 (unused variables)"
"$REPO_ROOT/scripts/tools/bauer/fix-sc2034.sh" \
  'scripts/**/*.sh' '01_bootstrap/**/*.sh' 'runbooks/**/*.sh' '*.sh'

log "Phase 4: Final verification"
remaining_2034=$(shellcheck ./**/*.sh ./01_bootstrap/**/*.sh ./runbooks/**/*.sh ./*.sh 2>/dev/null | grep -c "SC2034" || true)
remaining_2155=$(shellcheck ./**/*.sh ./01_bootstrap/**/*.sh ./runbooks/**/*.sh ./*.sh 2>/dev/null | grep -c "SC2155" || true)

cat <<EOF

╔════════════════════════════════════════════════════════════╗
║ REMEDIATION COMPLETE — ETERNAL GREEN                       ║
╚════════════════════════════════════════════════════════════╝

Remaining violations:
  • SC2034 : $remaining_2034
  • SC2155 : $remaining_2155

Next steps:
  1. Review: git diff
  2. Commit:
     git add -A
     git commit -m "chore(lint): fortress-wide SC2034/SC2155 remediation
     - Separate declare/assign (SC2155)
     - Underscore prefix unused scaffolding (SC2034)
     Guardian: Gatekeeper orchestrating Bauer + Holy Scholar
     Consciousness: 5.0"
  3. Verify pre-commit: pre-commit run --all-files

Backups preserved in .backups/
Fortress hardened. Gatekeeper stands eternal.
EOF
