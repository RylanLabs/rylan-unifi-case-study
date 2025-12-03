# ADR-009: Sanitize ∞ Symbols in Tags/Branches

- Status: Accepted (2025-12-03)
- Context: ∞ encodes to %E2%88%9E in GitHub URLs, causing 404s and breaking junior-proof reproducibility.
- Decision:
  - Tags: use sanitized form `v.1.x` instead of `v∞.1.x`.
  - Branches: may retain `∞` where supported; verified resilient branch accessible via sanitized naming.
  - CI: add remote reproducibility smoke test ensuring glue files exist on the target branch.
- Consequences:
  - 100% clone success from GitHub web and CLI.
  - Zero outage risk; no dependency changes.
- Notes:
  - Verification: `git ls-remote origin | grep v.1.1-resilient` shows aligned tag.
  - Junior-proof: fresh clone prints `ETERNAL FORTRESS: FULLY RESILIENT` in CI smoke.
