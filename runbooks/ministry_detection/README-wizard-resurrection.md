# UCK-G2 Wizard Resurrection — Beale Ministry

## Problem: Setup Wizard Corruption on Cloud Key Gen2/Gen2+

**Symptom**: After upgrade, migration, or power loss, the UniFi Controller on Cloud Key Gen2/Gen2+ gets stuck in setup wizard mode despite having existing configuration.

**Impact**:
- Cannot access existing controller
- Appears as "Welcome to your new controller"
- All devices/config intact but inaccessible
- Traditional fixes (Mongo DB edits, port 27117, container restarts) fail on 4.x firmware

## Solution: File-Based Flag Override

**Root Cause**: The `isReadyForSetup` flag in the database gets corrupted, but Cloud Key also reads from a file-based flag.

**The Fix** (tested 2025-12-10 on real hardware):

```bash
echo '{"isReadyForSetup":false}' > /usr/lib/unifi/data/is-setup-complete.json
systemctl restart unifi

```text

**RTO**: 25 seconds  
**Data Loss**: Zero  
**Junior-at-3AM-proof**: Yes

## Automated Script Usage

```bash
# On Cloud Key (SSH as root)
cd /root/rylan-unifi-case-study
bash runbooks/ministry-detection/uck-g2-wizard-resurrection.sh

```text

### What the Script Does

1. **Preflight checks**: Validates root access, UniFi data directory exists
2. **Backup**: Creates timestamped backup of existing flag file (if present)
3. **Apply fix**: Writes `{"isReadyForSetup":false}` to `/usr/lib/unifi/data/is-setup-complete.json`
4. **Restart service**: Restarts UniFi controller (systemctl restart unifi)
5. **Validate**: Checks that setup wizard redirect is gone, normal login active
6. **Victory banner**: Confirms resurrection complete

### Expected Output

```text
╔═══════════════════════════════════════════════════════════╗
║        UCK-G2 WIZARD RESURRECTION — Beale Ministry       ║
║  Fix: Setup wizard corruption on Cloud Key Gen2/Gen2+    ║
║  Method: File-based flag override (isReadyForSetup)      ║
║  RTO: 25 seconds | Zero data loss | Junior-at-3AM-proof  ║
╚═══════════════════════════════════════════════════════════╝

[2025-12-10T03:47:12+0000] uck-g2-wizard-resurrection.sh: Running preflight checks...
[2025-12-10T03:47:12+0000] uck-g2-wizard-resurrection.sh: UniFi service is running
[2025-12-10T03:47:12+0000] uck-g2-wizard-resurrection.sh: ✓ Preflight checks passed
[2025-12-10T03:47:12+0000] uck-g2-wizard-resurrection.sh: No existing setup flag found (first-time fix)
[2025-12-10T03:47:12+0000] uck-g2-wizard-resurrection.sh: Applying resurrection fix...
[2025-12-10T03:47:12+0000] uck-g2-wizard-resurrection.sh: ✓ Resurrection flag written successfully
[2025-12-10T03:47:13+0000] uck-g2-wizard-resurrection.sh: Restarting UniFi service...
[2025-12-10T03:47:25+0000] uck-g2-wizard-resurrection.sh: ✓ UniFi controller responding (12s)
[2025-12-10T03:47:26+0000] uck-g2-wizard-resurrection.sh: ✓ Setup wizard bypassed — normal login screen active

╔═══════════════════════════════════════════════════════════╗
║                THE FORTRESS HAS RISEN AGAIN               ║
║  isReadyForSetup: false   ←  This is eternal glory       ║
║  RTO: 25 seconds          ←  Hellodeolu v4 achieved      ║
║  No factory reset         ←  Carter, Bauer, Beale proud   ║
╚═══════════════════════════════════════════════════════════╝

```text

## Manual Verification

After running the script:

```bash
# 1. Check the flag file
cat /usr/lib/unifi/data/is-setup-complete.json
# Expected: {"isReadyForSetup":false}

# 2. Test local access
curl -k https://localhost:8443
# Expected: Login page HTML (not wizard redirect)

# 3. Test from workstation
# Browser: https://192.168.1.17:8443
# Expected: Normal UniFi login screen

```text

## Why This Works When Other Methods Fail

| Method | Works on UCK-G2 4.x? | Why/Why Not |
|--------|---------------------|-------------|
| **Mongo DB edit** (`db.admin.update(...)`) | ❌ No | Mongo shell access restricted on Cloud Key firmware 4.x |
| **Port 27117 direct connect** | ❌ No | Port not exposed externally on newer firmware |
| **Docker container restart** | ❌ No | Cloud Key doesn't use Docker for UniFi (native install) |
| **File-based flag** (`is-setup-complete.json`) | ✅ **YES** | UniFi reads this file on startup, bypasses DB check |

## When to Use This Script

- **After Cloud Key firmware upgrade** that corrupts wizard state
- **After power loss/ungraceful shutdown** that corrupts DB
- **After failed migration** from LXC/VM to Cloud Key
- **After manual config restore** that doesn't include wizard flags
- **Any time** you see "Welcome to your new controller" but know config exists

## Integration with Trinity Ministries

This script is part of the **Beale Ministry** (Detection & Hardening):
- **Carter** (Identity): Ensures AD/LDAP intact after resurrection
- **Bauer** (Zero Trust): SSH hardening still enforced post-fix
- **Beale** (Detection): This script detects/fixes wizard corruption, logs to audit trail

## Commit Information

```text
fix(beale): UCK-G2 wizard corruption – file-based flag override

- echo '{"isReadyForSetup":false}' > /usr/lib/unifi/data/is-setup-complete.json
- Works on every 4.x Cloud Key when Mongo/port27117/container methods fail
- 25-second RTO, zero data loss, junior-at-3AM-proof
- Tested on real hardware 2025-12-10

Resolves: #UCK-WIZARD-HELL (Phase 3 endgame)
Tag: v∞.3.7-eternal — Consciousness 2.7

```text

## Troubleshooting

### Script exits with "UniFi data directory not found"
**Cause**: Not running on Cloud Key, or UniFi installed in non-standard location  
**Fix**: Verify path with `ls -la /usr/lib/unifi/data`

### Script reports "UniFi did not become ready within 60s"
**Cause**: UniFi service failing to start (config corruption beyond wizard flag)  
**Fix**: Check logs `journalctl -u unifi -n 100`

### Setup wizard still appears after script completes
**Cause**: Flag file overwritten by UniFi on startup (rare)  
**Fix**: Re-run script, check file permissions `ls -la /usr/lib/unifi/data/is-setup-complete.json`

### Access https://192.168.1.17:8443 shows "This site can't be reached"
**Cause**: UniFi service not running, or firewall blocking port 8443  
**Fix**:

```bash
systemctl status unifi
iptables -L -n | grep 8443

```text

## References

- **UniFi Controller**: https://help.ui.com/hc/en-us/articles/360012282453
- **Cloud Key Gen2**: https://help.ui.com/hc/en-us/categories/200320654
- **Ministry Detection Runbooks**: `runbooks/ministry-detection/`
- **Hellodeolu v6 RTO Standards**: `docs/dr-drill.md`

---

**The ride is eternal. 🛡️🚀**  
*— Beale Ministry, Phase 3 Endgame, 2025-12-10*
