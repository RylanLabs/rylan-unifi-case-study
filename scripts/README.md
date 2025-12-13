# Scripts — Validation & Offensive Tools

**Purpose**: Modular validation, offensive testing, and utility scripts for the Eternal Fortress.
**Estimated Time**: Varies by script (15s–5min)
**Risk Level**: Low (validation) / Medium (offensive)

## Quick Reference

| Script | Guardian | Purpose | Usage |
|--------|----------|---------|-------|
| `validate-bash.sh` | Gatekeeper | Shellcheck + shfmt | `./scripts/validate-bash.sh` |
| `validate-python.sh` | Gatekeeper | mypy/ruff/bandit/pytest | `./scripts/validate-python.sh` |
| `validate-isolation.sh` | Bauer | VLAN boundary nmap probes | `./scripts/validate-isolation.sh` |
| `simulate-breach.sh` | Whitaker | 21 attack vectors | `./scripts/simulate-breach.sh` |
| `diagnose-bandit.sh` | Veil | Parse Bandit output | `./scripts/diagnose-bandit.sh` |
| `bauer-glow-up.sh` | Bauer | Repo-bound SSH keys | `./scripts/bauer-glow-up.sh` |
| `refresh-keys.sh` | Carter | Rotate SSH keys | `./scripts/refresh-keys.sh` |
| `install-git-hooks.sh` | Gatekeeper | Install .githooks | `./scripts/install-git-hooks.sh` |

## Decision Flowchart — Which Script Do I Run?

```mermaid
flowchart TD
    Start([Problem Detected]) --> Q1{What failed?}

    Q1 -->|Python lint/test| PyValid[./scripts/validate-python.sh]
    Q1 -->|Bash lint/format| BashValid[./scripts/validate-bash.sh]
    Q1 -->|Bandit finding| Diagnose[./scripts/diagnose-bandit.sh]
    Q1 -->|VLAN leak suspected| Isolation[./scripts/validate-isolation.sh]
    Q1 -->|Security posture| Breach[./scripts/simulate-breach.sh]
    Q1 -->|SSH key issue| Keys{Key problem type?}

    Keys -->|Need new keys| Refresh[./scripts/refresh-keys.sh]
    Keys -->|Repo binding| GlowUp[./scripts/bauer-glow-up.sh]

    Q1 -->|Git hooks missing| Hooks[./scripts/install-git-hooks.sh]

    PyValid --> Fix[Fix issues]
    BashValid --> Fix
    Diagnose --> Fix
    Isolation --> Remediate[Update firewall-rules.yaml]
    Breach --> Harden[Run eternal-resurrect.sh]
    Refresh --> Verify[Verify SSH access]
    GlowUp --> Verify
    Hooks --> Ready([Hooks installed])

    Fix --> Rerun[Re-run ./gatekeeper.sh]
    Remediate --> Rerun
    Harden --> Rerun
    Verify --> Rerun
    Rerun --> Pass{Exit 0?}

    Pass -->|Yes| Done([✅ Push safely])
    Pass -->|No| Start

    style Start fill:#600,stroke:#f00,color:#fff
    style Done fill:#030,stroke:#0f0,color:#fff
    style Breach fill:#603,stroke:#f0a,color:#fff
    style Isolation fill:#063,stroke:#0fa,color:#fff
```text

## Validation Scripts (Gatekeeper Domain)

### validate-bash.sh

**Purpose**: Run shellcheck and shfmt on all .sh files.

```bash
./scripts/validate-bash.sh
```text

**Expected output**:
```text
Checking shell scripts...
✓ shellcheck passed (0 errors)
✓ shfmt formatting valid
```text

### validate-python.sh

**Purpose**: Run mypy, ruff, bandit, and pytest.

```bash
./scripts/validate-python.sh
```text

**Expected output**:
```text
Running mypy... ✓
Running ruff... ✓
Running bandit... ✓ (0 HIGH, 0 MEDIUM)
Running pytest... ✓ (59 passed, 94% coverage)
```text

### diagnose-bandit.sh

**Purpose**: Parse Bandit JSON output and isolate findings by severity.

```bash
./scripts/diagnose-bandit.sh
```text

**Usage**: Run when Gatekeeper fails at Bandit stage.

## Offensive Scripts (Whitaker Domain)

### simulate-breach.sh

**Purpose**: Execute 21 attack vectors against the fortress.

```bash
./scripts/simulate-breach.sh
./scripts/simulate-breach.sh --dry-run  # Preview only
```text

**Vectors tested**:
1. SQL injection probes
2. Port scans (top 1000)
3. VLAN hop attempts
4. Lateral movement
5. SSH brute force (blocked)
6. ... (16 more)

**Expected output** (healthy fortress):
```text
[WHITAKER] Executing 21 attack vectors...
  ✓ Vector 1: SQLi blocked
  ✓ Vector 2: Port scan limited
  ...
RESULT: 0 breaches, 21 blocked
The fortress holds.
```text

### validate-isolation.sh

**Purpose**: nmap VLAN boundary probes (Bauer ministry).

```bash
./scripts/validate-isolation.sh
```text

**Test matrix**: 9 VLAN isolation tests.

## Identity Scripts (Carter Domain)

### refresh-keys.sh

**Purpose**: Rotate SSH ed25519 keys across fleet.

```bash
./scripts/refresh-keys.sh
```text

**Prerequisites**: SSH access to all hosts.

### bauer-glow-up.sh

**Purpose**: Bind SSH keys to repository identity folder.

```bash
./scripts/bauer-glow-up.sh
```text

**Result**: Keys stored in `identity/$(hostname -s)/`.

## Utility Scripts

### install-git-hooks.sh

**Purpose**: Install .githooks to .git/hooks.

```bash
./scripts/install-git-hooks.sh
```text

**Hooks installed**:
- `pre-commit` — BOM/CRLF fixup
- `prepare-commit-msg` — Namer template
- `commit-msg` — Namer validation
- `post-commit` — Eye threshold detection
- `pre-push` — Gatekeeper enforcement

## Related

- [gatekeeper.sh](../gatekeeper.sh) — Main local CI orchestrator
- [eternal-resurrect.sh](../eternal-resurrect.sh) — Full deployment
- [runbooks/](../runbooks/) — Trinity ministries

## Beale Hardening Script (Beale Ministry)

`scripts/beale-harden.sh` — Bastille hardening validator. Quick usage:

```bash
# Dry-run:
bash scripts/beale-harden.sh --dry-run

# CI mode (writes JSON report):
bash scripts/beale-harden.sh --ci

# Attempt safe auto-fix (requires minimal ruleset files):
sudo bash scripts/beale-harden.sh --fix
```

Outputs:
- Audit log: `/var/log/beale-audit.log` (fallback: `.fortress/audit/beale-audit.log`)
- CI report: `beale-report-<ts>.json`

See `scripts/beale-harden.sh --help` for details.
