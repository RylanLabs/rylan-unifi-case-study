# Canon — The 10 Eternal Attachments

This directory contains the sealed canon of the rylan-unifi-case-study fortress — the 10 attachments that encode the complete vision, execution strategy, and sacred glue for eternal reproducibility.

## The Trinity of Books (Assimilated)

1. **Carter** — Network Warrior: Practical network engineering, zero-trust segmentation, hardware offload reality.
2. **Bauer** — Essential System Administration: Operational discipline, disaster recovery, backup orchestration.
3. **Suehring** — Harden Linux: Security hardening, CIS benchmarks, audit logging, PKI foundation.

## The 10 Sacred Attachments

1. **Phase 1 Blueprint** — Zero-trust policy table, 10-rule lockdown, USG-3P offload preservation.
2. **Phase 2 Blueprint** — FreeRADIUS + PEAP-MSCHAPv2, internal CA, rogue DHCP webhook, eternal CI.
3. **Architecture Diagram** — Mermaid v5 topology, VLAN segmentation, service matrix.
4. **ADR Index** — All architecture decision records (ADR-001 through ADR-005+).
5. **Disaster Recovery Runbook** — Complete DR drill, backup verification, restore procedures.
6. **CI/CD Pipeline Spec** — Eternal validation workflow, rule count enforcement, FreeRADIUS syntax check.
7. **Guardian Audit Log** — Python audit script with YAML/JSON validation, git commit tracking.
8. **Backup Orchestrator** — Nightly rsync + Samba AD backup to NAS, retention policy.
9. **Test Suite** — Pytest coverage for apply.py, triage engine, network isolation validator.
10. **Semantic Versioning Manifest** — pyproject.toml with v∞.1.0-eternal lock, dependency pinning.

## Eternal Reproducibility

The fortress can be resurrected from a clean clone:

```bash
git clone https://github.com/T-Rylander/rylan-unifi-case-study.git
cd rylan-unifi-case-study
git checkout release/v∞.1.0-eternal
./eternal-resurrect.sh
```

## Sacred Glue (Must Always Exist)

| Path | Function | Canonical | Notes |
|------|----------|-----------|-------|
| `eternal-resurrect.sh` | One-command fortress deployment | Bash | Ubuntu 24.04, source .env |
| `bootstrap/samba-dc-provision.sh` | Canonical AD/DC provisioning | Bash | Ubuntu 24.04 (WSL2 on Windows) |
| `bootstrap/samba-dc-test.ps1` | Dev-only reference (Windows) | PowerShell | Feature branches only, not merged to main |
| `guardian/audit-eternal.py` | PII redaction + audit trail | Python | importlib.util lazy Presidio |
| `.github/workflows/ci-validate.yaml` | Eternal validation pipeline | Bash/Python | Pytest, orchestrator smoke test |
| `docs/canon/README.md` | This file (sealed forever) | Markdown | Canonical trinity reference |
| `.env.example` | Hardware-agnostic configuration | Bash | Copy to .env, customize for your environment |

### Windows Development Workflow (Trinity-Compliant)

For Windows engineers working on this fortress:

1. **Install WSL2 Ubuntu 24.04**:
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```

2. **Clone repository inside WSL**:
   ```bash
   wsl
   cd /mnt/c/Path/To/Repos
   git clone https://github.com/T-Rylander/rylan-unifi-case-study.git
   cd rylan-unifi-case-study
   ```

3. **Run canonical bash scripts**:
   ```bash
   source .env
   bash bootstrap/samba-dc-provision.sh
   bash eternal-resurrect.sh
   ```

4. **Optional: Use PowerShell for Multipass testing** (feature branch only):
   ```powershell
   # Windows-specific Multipass testing (feature branches)
   cd F:\Sources\Repos\rylan-unifi-case-study-iot
   .\bootstrap\samba-dc-test.ps1
   
   # NOTE: samba-dc-test.ps1 is dev-only reference.
   # Port to bash (samba-dc-provision.sh) before merging to main.
   ```

### CI Guard: Bash Enforcement in Main Branch

All Pull Requests to `main` must pass this check:

```yaml
# .github/workflows/ci-validate.yaml
- name: Enforce canonical bash (block PowerShell in main branch)
  run: |
    if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
      if find bootstrap/ -name "*.ps1" 2>/dev/null | grep -q .; then
        echo "❌ PowerShell scripts not allowed in main branch"
        echo "   Port to bash (bootstrap/samba-dc-provision.sh) before merging"
        exit 1
      fi
    fi
```

This directory is **sealed** — changes require ADR approval and Phase increment.

**Status:** Phase -∞ → v∞.1.0-eternal complete
**Last Updated:** December 2025
**Custodian:** Human vision + AI execution = eternal truth
