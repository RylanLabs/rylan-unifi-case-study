# UniFi Runbooks — Junior-at-3-AM Guidance
**Eternal operational playbooks (Beale + Whitaker disciplines).**

## Runbooks
- `cloudkey-backup-runbook.md` — Daily backup procedures (encryption, verification, retention)
- `migration-runbook.md` — Network migration (dry-run → apply → verify → rollback)
- `declarative-apply-runbook.md` — Config deployment (diff → approve → push)

## Philosophy
- **No surprises**: Always dry-run first
- **Atomic**: All-or-nothing deployments (no partial applies)
- **Auditable**: Every action logged (with timestamp, user, delta)
- **Reversible**: Rollback guaranteed <15 min

## Entry Point
```bash
grep -r "^\#\# Start" *.md | head -1  # Find next step
```
