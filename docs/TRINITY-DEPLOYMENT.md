# TRINITY DEPLOYMENT — Dry-run & Environment

This document describes the `--dry-run` behavior of `scripts/ignite.sh` and the recommended `.env` workflow.

## Goal
Allow safe previews for local users and CI without requiring secrets while keeping strict validation for live deployments.

## Behavior (Option 3: `.env.example` fallback)

- `--dry-run` tries, in order:
  1. Load `.env` if present (real config — more accurate preview)
  2. Else load `.env.example` if present (example values for safe preview)
  3. Else continue with warnings and defaults

- Live runs (no `--dry-run`) require a real `.env` file and will fail fast if required variables are missing.

## Locking (user-friendly dry-run)

- Live runs use the system lock at `/var/run/ignite.lock` and require root permissions.
- Dry-run uses a per-user runtime lock (prefers `${XDG_RUNTIME_DIR:-/run/user/$UID}`), and will attempt to create the parent directory if missing.
- If the lock directory cannot be created or the lock file cannot be written and the run is a dry-run, the script will log a warning and continue without taking a lock (safe for preview).

## How to preview locally

```bash
# Quick preview using example values
./scripts/ignite.sh --dry-run

# More accurate preview with your values (copy and edit first)
cp .env.example .env
# Edit .env to your environment (do not commit .env)
./scripts/ignite.sh --dry-run
```

## How to run for real

```bash
# Live deployment — requires root and a filled .env
sudo ./scripts/ignite.sh
```

## Notes for CI

- CI jobs should run `./scripts/ignite.sh --dry-run`; ensure `.env.example` remains in the repo.
- Do not add real secrets to CI; use CI secrets only for live deployment pipelines.
