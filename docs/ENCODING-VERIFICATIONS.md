# Encoding Verifications

This file documents verified UTF-8 + LF encodings for critical scripts.

- `runbooks/ministry-secrets/rylan-carter-eternal-one-shot.sh` — Verified 2025-12-08 UTC
  - Encoding: UTF-8 (no BOM)
  - Line endings: LF (Unix)
  - File size: 4310 bytes
  - Verification method: raw byte inspection on Windows PowerShell (`[System.IO.File]::ReadAllBytes`) — checked for BOM bytes `239 187 191` and CR (13) presence.

If you need more files validated, add them to this document and request verification.

## Batch normalization: 2025-12-08 04:44:18Z

- FIXED|D:\Repos\rylan-unifi-deploy\01-bootstrap\freeradius\clients.conf|BOM:False|CR:True|OrigBytes:108|NewBytes:103
- FIXED|D:\Repos\rylan-unifi-deploy\docs\blueprints\enlightenment-blueprint-v1.0-final.txt|BOM:False|CR:True|OrigBytes:3688|NewBytes:3602
- FIXED|D:\Repos\rylan-unifi-deploy\docs\DEVICE-PASSPORT-IMPLEMENTATION.md|BOM:False|CR:True|OrigBytes:11718|NewBytes:11304
- FIXED|D:\Repos\rylan-unifi-deploy\docs\ENCODING-VERIFICATIONS.md|BOM:False|CR:True|OrigBytes:535|NewBytes:524
- FIXED|D:\Repos\rylan-unifi-deploy\docs\GAP-CLOSURE-SUMMARY.md|BOM:False|CR:True|OrigBytes:15209|NewBytes:14703
- FIXED|D:\Repos\rylan-unifi-deploy\rylan_ai_helpdesk\triage_engine\requirements.txt|BOM:True|CR:True|OrigBytes:215|NewBytes:203
- FIXED|D:\Repos\rylan-unifi-deploy\Phase 3 endgame? v2.0-eternal.txt|BOM:False|CR:True|OrigBytes:81241|NewBytes:78724
- FIXED|D:\Repos\rylan-unifi-deploy\requirements-unifi.txt|BOM:False|CR:True|OrigBytes:92|NewBytes:87
- FIXED|D:\Repos\rylan-unifi-deploy\requirements.txt|BOM:False|CR:True|OrigBytes:239|NewBytes:227
- FIXED|D:\Repos\rylan-unifi-deploy\VICTORY-BANNER.txt|BOM:False|CR:True|OrigBytes:6701|NewBytes:6568
