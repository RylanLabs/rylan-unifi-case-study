# ADR-008: Trinity Ministries Sequencing

- Status: Accepted
- Date: 2025-12-05
- Authors: Hellodeolu v4 (AI Architect)
- Context: Final crystallization of the Carter → Bauer → Suehring pipeline with strict ordering, 10-rule cap, and lean repo budget.

---

## Decision

- Keep exactly three ministries in order: **Carter (Secrets)** → **Bauer (Whispers)** → **Suehring (Perimeter)**. No parallelism.
- Orchestrate via `scripts/ignite.sh` v4.0 with exit-on-fail and human confirms:
    - "Phase 1 complete — continue to Whispers? [y/N]"
    - "Phase 2 complete — continue to Perimeter? [y/N]"
- Final validation entrypoint: `scripts/validate-eternal.sh` (root wrapper delegates).
- Suehring policy table locked to **≤10 rules** in `02-declarative-config/policy-table.yaml` (hardware offload safe for USG-3P).
- CI (`.github/workflows/ci-trinity.yaml`) enforces runbook presence, ignite sequencing, ≤10 rules, and repository size **≤150 files**.
- PowerShell and PXE experiment bloat removed to keep junior-at-3-AM deployable footprint.

## Consequences

- Any new network control must fit inside the 10-rule budget; consolidation is required before additions.
- Automation must supply the expected `[y/N]` confirmations if non-interactive runs are desired.
- Validation changes land in `scripts/validate-eternal.sh`; legacy callers use the root wrapper transparently.
- Repo growth past 150 files blocks CI, keeping audits lean and diffs readable.

## Validation

- Run `sudo ./scripts/ignite.sh` to execute Carter → Bauer → Suehring, then call `scripts/validate-eternal.sh` for eternal green.
- CI gates: grep-based rule count check (≤10), ignite prompt checks, file budget check (≤150), and syntax checks for all phases.

## Rollback

- Restore previous `ci-trinity.yaml`, `scripts/ignite.sh`, `02-declarative-config/policy-table.yaml`, and `scripts/validate-eternal.sh` if the sequence or rule budget must be relaxed; rerun CI to verify.

## References

- INSTRUCTION-SET-ETERNAL-v1.md (Trinity canon)
- Carter (identity), Bauer (hardening), Suehring (perimeter) — immutable phase names.
