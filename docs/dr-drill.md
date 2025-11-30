# Disaster Recovery Drill

## Objective
Validate ability to restore UniFi controller and helpdesk services within RTO (2h).

## Quarterly Drill Steps
1. Export current backup set and verify integrity.
2. Provision clean VM; install controller script.
3. Restore `/var/lib/unifi/data` from archive.
4. Start controller; verify device adoption reappears.
5. Run isolation validation script.
6. Simulate ticket ingestion; ensure triage engine responds.
7. Document timings, gaps, improvements.

## Success Criteria
- Controller operational < 45 minutes.
- All VLANs present and active.
- Policy routes re-applied manually.
- No isolation test failures.
