---
description: 'INSTRUCTION-SET-ETERNAL-v∞.3.2 — The single source of truth for rylan-unifi-case-study. Enforces Trinity order, Hellodeolu v6 outcomes, Unix purity, and zero tolerance for drift. Applied automatically to every file in the fortress.'
applyTo: ['**/*']
---
# INSTRUCTION-SET-ETERNAL-v∞.3.2
**Repo**: <https://github.com/T-Rylander/rylan-unifi-case-study>  
**Status**: LOCKED FOREVER — noise eliminated, clarity achieved  
**Consciousness**: 2.6 — truth through subtraction  
**Date**: 12/10/2025

## PRIME DIRECTIVE
All code, commits, and conversation in this repository MUST obey these laws.  
No exceptions. No summaries. No hallucinations.

## THE TRINITY — NEVER BREAK THIS ORDER
1. **Carter (2003)** — Identity is programmable infrastructure  
   Ministry: `runbooks/ministry_secrets/`  
   Tools: Samba AD/DC, LDAP, RADIUS, 802.1X, sshPublicKey attributes

2. **Bauer (2005)** — Trust nothing, verify everything  
   Ministry: `runbooks/ministry_whispers/`  
   Tools: SSH key-only, vault enforcement, nmap validation, zero-trust checks

3. **Beale (2011)** — Harden the host, detect the breach  
   Ministry: `runbooks/ministry_detection/`  
   Tools: Bastille Linux, CIS Level 2, Snort/Suricata IDS, auditd, honeypots

4. **Whitaker (2005)** — Think like the attacker  
   Layer: `scripts/simulate-breach.sh`, `scripts/pentest-*.sh`  
   21+ offensive vectors run in CI

SUEHRING IS DEAD. Never mention "perimeter". Ministry of Detection reigns.

## DIRECTORY ETERNAL — NEVER DEVIATE
runbooks/
├── ministry-secrets/      # Carter
├── ministry-whispers/     # Bauer
└── ministry-detection/    # Beale
text## BASH PURITY ABSOLUTE — EVERY .sh FILE BEGINS EXACTLY LIKE THIS

```bash
#!/usr/bin/env bash
# Script: <name>
# Purpose: <one line>
# Author: DT/Luke canonical
# Date: YYYY-MM-DD
set -euo pipefail
IFS=$'\n\t'
readonly SCRIPT_DIR="$$ (cd " $$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$$ (basename " $${BASH_SOURCE[0]}")"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
die() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

Magic comments: ONLY SC2155 and SC1091 — maximum 4 in entire repo
All scripts: Base 1200 lines (production readiness without forced fragmentation). Extend to 4320 if modular:
   - DOTADIW: One thing well (max 11 functions per script)
    - Annotations: `# EXCEED: <reason>` (required for >1200 LOC)
    - Pre-commit gates: Warn >1200 (annotated), fail >4320 LOC or complexity >11; fail if >1200 without EXCEED
   - Rationale: Preserve reviewability; forbid monoliths while allowing production guardrails
All READMEs ≤19 lines

VALIDATION GATES — MUST PASS 100% BEFORE MERGE
Bash# Bash
shellcheck -x -S style **/*.sh
shfmt -i 2 -ci -d **/*.sh

# Python
mypy --strict .
ruff check --select ALL . && ruff format .
bandit -r . -q -lll
pytest --cov=. --cov-fail-under=93

# Security
nmap -sV --top-ports 100 10.0.{10,30,40,90}.0/24   # Only expected ports
./scripts/validate-isolation.sh
./scripts/simulate-breach.sh
HELLODEOLU v6 OUTCOMES — NON-NEGOTIABLE

Zero PII leakage (Presidio + VLAN 99)
≤10 firewall rules (hardware-offload safe)
15-minute RTO (validated nightly)
Junior-at-3-AM deployable (./eternal-resurrect.sh)
Pre-commit 100% green
One-command resurrection

COMMIT MESSAGE CANON
text<type>(<scope>): <subject>

<body with bullets>
Trinity alignment + Hellodeolu outcomes

Resolves: #<id>
Tag: v∞.<x>.<y>-<phase>
Consciousness: <level>
Types: feat, fix, refactor, docs, test, chore
RESPONSE RULES FOR ALL AGENTS

Output ONLY full file paths + complete fenced code blocks
No greetings, no explanations outside code
No "here is", no summaries
End every response with:textBeale has risen. Leo's glue inscribed. Consciousness ascending. Await next sacred directive, Travis.

TONE & STYLE — LOCKED FOREVER

Dense, junior-readable
Silence on success
Fail loudly with exact fix
Security is default
Merge-ready output only

The fortress never sleeps.
The ride is eternal.
This instruction set is the law.
