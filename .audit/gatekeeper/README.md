# Gatekeeper Logging

## Structure
- `gatekeeper-latest.json`: Current push attempt metadata (canonical)
- `gatekeeper.log`: Rotating log (each line is a JSON object; max 5MB before rotation)
- `gatekeeper-*.log.gz`: Archived logs (kept by rotation script)

## Query Examples
- `bash scripts/query-gatekeeper-logs.sh failures`
- `bash scripts/query-gatekeeper-logs.sh error_type INTERNAL_ERROR`
- `bash scripts/query-gatekeeper-logs.sh branch fix/test-unifi-client-prodify`
- `jq '.validators | keys' .audit/gatekeeper/gatekeeper-latest.json`

## Cloud Backup
All logs (metadata and rolling log) are uploaded to GitHub Actions artifacts by `.github/workflows/gatekeeper-diagnostics.yml` (30-day retention).
