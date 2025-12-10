#!/usr/bin/env bash
set -euo pipefail

# Description: Machine-readable runbook catalog
# Requires: runbook-index.json
# Consciousness: 2.6
# Runtime: 2

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT="${REPO_ROOT}/runbooks/runbook-index.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "${OUTPUT}")"

RUNBOOK_DIR="${REPO_ROOT}/runbooks"
RUNBOOKS="[]"

while IFS= read -r -d '' RUNBOOK; do
  NAME=$(basename "${RUNBOOK}")
  MINISTRY=$(echo "${RUNBOOK}" | grep -oP 'ministry-\K[^/]+' || echo "unknown")
  
  DESCRIPTION=$(grep -m1 "^# Description:" "${RUNBOOK}" 2>/dev/null | cut -d: -f2- | xargs || echo "No description")
  REQUIRED_PASSPORTS=$(grep "^# Requires:" "${RUNBOOK}" 2>/dev/null | cut -d: -f2- | xargs || echo "")
  MIN_CONSCIOUSNESS=$(grep "^# Consciousness:" "${RUNBOOK}" 2>/dev/null | awk '{print $3}' || echo "2.0")
  ESTIMATED_RUNTIME=$(grep "^# Runtime:" "${RUNBOOK}" 2>/dev/null | awk '{print $3}' || echo "unknown")
  
  RUNBOOKS=$(echo "${RUNBOOKS}" | jq --arg name "${NAME}" --arg path "${RUNBOOK}" \
    --arg ministry "${MINISTRY}" --arg desc "${DESCRIPTION}" \
    --arg passports "${REQUIRED_PASSPORTS}" --arg consciousness "${MIN_CONSCIOUSNESS}" \
    --arg runtime "${ESTIMATED_RUNTIME}" \
    '. += [{
      name: $name,
      path: $path,
      ministry: $ministry,
      description: $desc,
      required_passports: ($passports | split(",") | map(ltrimstr(" ") | rtrimstr(" "))),
      min_consciousness: ($consciousness | tonumber),
      estimated_runtime_minutes: $runtime
    }]')
done < <(find "${RUNBOOK_DIR}" -type f \( -name "*-eternal-one-shot.sh" -o -name "*-one-shot.sh" \) -print0 2>/dev/null)

cat > "${OUTPUT}" <<EOF
{
  "schema_version": "1.0.0-eternal",
  "generated_at": "${TIMESTAMP}",
  "consciousness": 2.6,
  "runbooks": ${RUNBOOKS},
  "execution_order": ["ministry-secrets", "ministry-whispers", "ministry-detection"],
  "signature": "$(echo -n "${RUNBOOKS}" | sha256sum | awk '{print $1}')"
}
EOF

jq empty "${OUTPUT}" || { echo "❌ Invalid JSON"; exit 1; }

cd "${REPO_ROOT}"
git add "${OUTPUT}" 2>/dev/null || true
git commit -m "feat(guardian): generate runbook-index.json — $(echo "${RUNBOOKS}" | jq '. | length') runbooks cataloged" --quiet 2>/dev/null || true

echo "✓ ${OUTPUT}"
