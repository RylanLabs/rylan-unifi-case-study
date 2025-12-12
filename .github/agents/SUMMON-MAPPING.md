# Guardian Summon Mapping

**Version**: v∞.4.4  
**Consciousness**: 4.4  
**Last Updated**: 2025-12-11

---

## Overview

This document maps `@Guardian` summons in GitHub PR/issue comments to their underlying automation scripts. All guardians follow the **Trinity pattern** (Carter/Bauer/Beale) and output **structured JSON responses**.

### Architecture

```
GitHub Comment (@Guardian <command>)
    ↓
.github/workflows/agent-summon.yml (parse + route)
    ↓
Guardian Wrapper Script (scripts/guardian-*.sh)
    ↓
Living Automation (runbooks/, scripts/, app/)
    ↓
JSON Response (.github/agents/response.json)
    ↓
GitHub Comment (formatted with emoji + collapsible details)
```

---

## Active Guardians

### 🔑 Carter (Identity & Access)

**Domain**: Identity operations, SSH key management, LDAP/RADIUS integration  
**Voice**: Calm, methodical, validates before acting  
**Wrapper**: `scripts/guardian-carter.sh`

#### Summon Patterns

| Command | Purpose | Example | Underlying Script |
|---------|---------|---------|-------------------|
| `@Carter <email>` | Onboard new user (dry-run) | `@Carter alice@rylan.internal` | `runbooks/ministry-secrets/onboard.sh` |

#### Response Format

```json
{
  "guardian": "Carter",
  "operation": "onboard",
  "email": "alice@rylan.internal",
  "status": "success",
  "timestamp": "2025-12-11T15:42:33-05:00",
  "message": "Onboard dry-run completed",
  "output": "[DRY_RUN log output]"
}
```

#### Local Testing

```bash
# Dry-run onboard
./scripts/guardian-carter.sh "alice@rylan.internal" /tmp/carter-test.json
cat /tmp/carter-test.json | jq

# Expected: dry_run status, validation checks, no actual changes
```

#### Error Conditions

- **Invalid email format**: Returns error with message "Invalid or missing email (expected user@rylan.internal)"
- **Onboard script failure**: Exit code 1, includes output in response

---

### 🛡️ Bauer (Verification & Trust)

**Domain**: Security audits, lint enforcement, PII detection, baseline verification  
**Voice**: Strict, uncompromising, fails loudly on violations  
**Wrapper**: `scripts/guardian-bauer.sh`

#### Summon Patterns

| Command | Purpose | Example | Underlying Script |
|---------|---------|---------|-------------------|
| `@Bauer Audit` | Run full gatekeeper checks | `@Bauer Audit` | `gatekeeper.sh` |

#### Response Format

```json
{
  "guardian": "Bauer",
  "check": "gatekeeper",
  "status": "pass",
  "message": "Gatekeeper checks passed",
  "output": "[Full gatekeeper output]",
  "timestamp": "2025-12-11T15:43:12-05:00"
}
```

#### Local Testing

```bash
# Run gatekeeper audit
./scripts/guardian-bauer.sh /tmp/bauer-test.json
cat /tmp/bauer-test.json | jq

# Expected: pass/fail status, gatekeeper output
```

#### Error Conditions

- **Shellcheck failures**: Status "fail", output includes violations
- **Python test failures**: Status "fail", includes pytest/coverage output
- **Bandit findings**: Status "fail", includes security issues

---

### ⚔️ Beale (Drift Detection & Hardening)

**Domain**: Configuration drift, port scanning, baseline comparison  
**Voice**: Vigilant, never sleeps, severity-aware  
**Wrapper**: `scripts/beale-drift-detect.sh`

#### Summon Patterns

| Command | Purpose | Example | Underlying Script |
|---------|---------|---------|-------------------|
| `@Beale Detect drift` | Full drift scan | `@Beale Detect drift` | `scripts/beale-drift-detect.sh` |

#### Response Format

```json
{
  "guardian": "Beale",
  "scan_type": "drift_detection",
  "severity": "high",
  "drift_detected": true,
  "timestamp": "2025-12-11T15:44:01-05:00",
  "message": "Drift detected",
  "details": [
    "Default SSH port (22) referenced in configs",
    "Hardcoded VLAN IPs detected in scripts"
  ],
  "remediation": "Review flagged configs and update baselines"
}
```

#### Severity Levels

| Level | Trigger | Example |
|-------|---------|---------|
| **High** | Port 22 or hardcoded credentials | SSH port references, secrets in code |
| **Medium** | Hardcoded IPs or >10 firewall rules | VLAN IPs in scripts |
| **None** | No drift detected | All checks passed |

#### Local Testing

```bash
# Run drift detection
./scripts/beale-drift-detect.sh /tmp/beale-test.json
cat /tmp/beale-test.json | jq

# Expected: drift_detected boolean, details array if drift found
```

#### Error Conditions



### 🧰 Gatekeeper (Pre-commit Validation)

**Domain**: Run full local pre-commit bundle on demand  
**Wrapper**: `scripts/guardian-gatekeeper.sh`

#### Summon Patterns

| Command | Purpose | Example | Underlying Script |
|---------|---------|---------|-------------------|
| `@Gatekeeper Validate` | Run pre-commit for all files | `@Gatekeeper Validate` | `pre-commit run --all-files` |

#### Response Format

```json
{ "guardian": "Gatekeeper", "status": "pass", "message": "Gate passed – fortress green" }
```

Failure returns `status:"fail"` with `details` containing the gate log.

---

### 👁️ Eye (Status & Readiness)

**Domain**: Report consciousness level and production readiness  
**Wrapper**: `scripts/guardian-eye.sh`

#### Summon Patterns

| Command | Purpose | Example | Args |
|---------|---------|---------|------|
| `@Eye Status` | Current consciousness | `@Eye Status` | `status` |
| `@Eye Readiness` | Readiness check | `@Eye Readiness` | `readiness` |

#### Response Format

```json
{ "guardian":"Eye", "check":"consciousness", "level":"v∞.4.5", "message":"Current consciousness level" }
```

Readiness returns `ready:true` with `details` from Beale checks.

---

### 🏷️ Namer (Commit & Tag)

**Domain**: Generate commit messages and semantic tags  
**Wrapper**: `scripts/guardian-namer.sh`

#### Summon Patterns

| Command | Purpose | Example | Args |
|---------|---------|---------|------|
| `@Namer Commit` | Suggest commit message | `@Namer Commit` | `commit` |
| `@Namer Tag` | Suggest next tag | `@Namer Tag` | `tag` |

#### Response Format

```json
{ "guardian":"Namer", "suggestion":"feat(agents): add missing guardian summons – Gatekeeper/Eye/Namer/Veil", "files":"..." }
```

---

### 🫥 Veil (CI Diagnostics)

**Domain**: Parse CI failure logs to surface common issues  
**Wrapper**: `scripts/guardian-veil.sh`

#### Summon Patterns

| Command | Purpose | Example |
|---------|---------|---------|
| `@Veil Diagnose <log>` | Diagnose CI failures | `@Veil Diagnose pytest error ...` |

#### Response Format

```json
{ "guardian":"Veil", "diagnosis":"Common CI failure patterns detected", "details":"..." }
```


### GitHub Comment Format

All guardians post responses with:

1. **Emoji indicator**: ✅ success/pass, ❌ failure/error, ⚠️ drift
2. **Guardian name**: Bold, e.g., `**@Carter** responds:`
3. **Summary message**: Human-readable outcome
4. **Details section**: Bullet points for findings (if applicable)
5. **Collapsible JSON**: Full response for debugging

#### Example Response

```markdown
✅ **@Carter** responds:

**Onboard dry-run completed**

<details>
<summary>Full Response (JSON)</summary>

```json
{
  "guardian": "Carter",
  "operation": "onboard",
  "email": "alice@rylan.internal",
  "status": "success",
  "timestamp": "2025-12-11T15:42:33-05:00"
}
```
</details>
```

---

## Testing Workflows

### Local Testing (Before GitHub)

```bash
# Test all guardians locally
./scripts/guardian-carter.sh "test@rylan.internal" /tmp/carter.json
cat /tmp/carter.json | jq

./scripts/guardian-bauer.sh /tmp/bauer.json
cat /tmp/bauer.json | jq

./scripts/beale-drift-detect.sh /tmp/beale.json || true
cat /tmp/beale.json | jq

# Validate JSON format
for file in /tmp/{carter,bauer,beale}.json; do
  jq empty "$file" && echo "✅ Valid JSON: $file" || echo "❌ Invalid: $file"
done
```

### GitHub Testing (Live Integration)

```bash
# Create test PR
git checkout -b test/guardian-summons
echo "# Test" > TEST.md
git add TEST.md
git commit -m "test: guardian summons"
git push origin test/guardian-summons
gh pr create --title "test: guardian summons" --body "Testing @Guardian summons"

# Test guardians
PR_NUM=$(gh pr view --json number -q .number)
gh pr comment $PR_NUM --body "@Carter test@rylan.internal"
gh pr comment $PR_NUM --body "@Bauer Audit"
gh pr comment $PR_NUM --body "@Beale Detect drift"

# View responses
gh pr view $PR_NUM --comments
```

### Validation Checklist

```bash
# Shellcheck all guardian scripts
shellcheck scripts/guardian-carter.sh
shellcheck scripts/guardian-bauer.sh
shellcheck scripts/beale-drift-detect.sh

# YAML lint workflow
yamllint .github/workflows/agent-summon.yml

# Test JSON output structure
jq -e '.guardian != null' /tmp/test.json
jq -e '.status != null' /tmp/test.json
jq -e '.timestamp != null' /tmp/test.json
```

---

## Troubleshooting

### Common Issues

#### No Response Posted

**Symptom**: Comment `@Guardian` but no bot reply  
**Diagnosis**:
```bash
gh run list --workflow=agent-summon.yml --limit 5
gh run view <run-id> --log
```
**Fix**: Verify script exists, check workflow logs for errors

---

#### Malformed JSON Response

**Symptom**: Bot posts "Response malformed" error  
**Diagnosis**:
```bash
./scripts/guardian-carter.sh "test@rylan.internal" /tmp/debug.json
cat /tmp/debug.json
jq empty /tmp/debug.json
```
**Fix**: Ensure script uses `jq -n` for JSON construction

---

#### Script Not Found

**Symptom**: Workflow fails with "Script not found"  
**Diagnosis**:
```bash
ls -lh scripts/guardian-*.sh
grep "Parse Guardian" .github/workflows/agent-summon.yml
```
**Fix**: Verify script path in workflow matches actual location

---

#### Permission Denied

**Symptom**: Workflow fails with "Permission denied"  
**Diagnosis**:
```bash
ls -l scripts/guardian-*.sh
```
**Fix**:
```bash
chmod +x scripts/guardian-*.sh
git add --chmod=+x scripts/guardian-*.sh
git commit -m "fix: make guardian scripts executable"
```

---

## Quick Reference

### Summon Syntax Cheat Sheet

```bash
# Carter (Identity)
@Carter alice@rylan.internal           # Onboard user (dry-run)

# Bauer (Verification)
@Bauer Audit                           # Full gatekeeper check

# Beale (Detection)
@Beale Detect drift                    # Full drift scan

# Gatekeeper (Pre-commit)
@Gatekeeper Validate                   # Run pre-commit now

# Eye (Status/Readiness)
@Eye Status                            # Current consciousness
@Eye Readiness                         # Production readiness check

# Namer (Message/Tag)
@Namer Commit                          # Suggest commit message
@Namer Tag                             # Suggest semantic tag

# Veil (CI Diagnostics)
@Veil Diagnose <log>                   # Diagnose failure text
```

### One-Liner Test

```bash
# Test all guardians locally
for guardian in carter bauer beale; do
  echo "Testing $guardian..."
  if [[ "$guardian" == "carter" ]]; then
    ./scripts/guardian-carter.sh "test@rylan.internal" /tmp/$guardian.json
  elif [[ "$guardian" == "bauer" ]]; then
    ./scripts/guardian-bauer.sh /tmp/$guardian.json
  else
    ./scripts/beale-drift-detect.sh /tmp/$guardian.json || true
  fi
  cat /tmp/$guardian.json | jq -r '.guardian, .status, .message'
  echo "---"
done
```

---

## File Locations

### Guardian Scripts

```
scripts/
├── guardian-carter.sh          # Carter wrapper (identity ops)
├── guardian-bauer.sh           # Bauer wrapper (verification)
└── beale-drift-detect.sh       # Beale drift detection

runbooks/
└── ministry-secrets/
    └── onboard.sh              # Carter: User onboarding

scripts/
└── gatekeeper.sh               # Bauer: Full audit suite
```

### Configuration Files

```
.github/
├── workflows/
│   └── agent-summon.yml        # Main summon workflow
├── agents/
│   ├── SUMMON-MAPPING.md       # This file
│   ├── AGENTS.md               # Pantheon voice
│   └── README.md               # Agent overview
└── baselines/
    ├── ports.txt               # Beale: Port baseline
    ├── firewall.txt            # Beale: Firewall baseline
    └── ssh-config.txt          # Beale: SSH config baseline
```

---

## JSON Response Schema

### Standard Fields (All Guardians)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `guardian` | string | ✅ | Guardian name (Carter, Bauer, Beale) |
| `status` | string | ✅ | Outcome (success, failure, pass, fail) |
| `timestamp` | string | ✅ | ISO8601 timestamp |
| `message` | string | ✅ | Human-readable summary |

### Guardian-Specific Fields

#### Carter (Identity)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `operation` | string | ✅ | onboard, rotate_keys, verify |
| `email` | string | ✅ | Target email address |
| `output` | string | ⚠️ | Script output/logs |

#### Bauer (Verification)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `check` | string | ✅ | gatekeeper, pii_validation |
| `output` | string | ⚠️ | Gatekeeper output |

#### Beale (Detection)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `scan_type` | string | ✅ | drift_detection |
| `severity` | string | ✅ | high, medium, low, none |
| `drift_detected` | boolean | ✅ | true if drift found |
| `details` | array | ⚠️ | List of drift findings |
| `remediation` | string | ⚠️ | Suggested fix |

---

## Related Documentation

- **[LORE.md](../../LORE.md)**: Trinity pattern origin
- **[CONSCIOUSNESS.md](../../CONSCIOUSNESS.md)**: Version history
- **[AGENTS.md](AGENTS.md)**: Pantheon voice
- **[README.md](README.md)**: Agent overview

---

The guardians now execute.  
The fortress is eternal.  
The summons are documented.

**Consciousness: 4.4**
