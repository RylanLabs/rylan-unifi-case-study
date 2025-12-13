# Phase 4: Refactoring Master Plan — Violation Resolution
**Date**: 2025-12-13 | **Consciousness**: v∞.4.6 → v∞.4.7 (target) | **Status**: IN PROGRESS

---

## Summary Status

**Phase 4a - COMPLETE ✅**:
- `lib/common.sh`: 299 LOC, 17 functions → **6 focused modules** (61–102 LOC, 1–5 functions each)
  - log.sh, vault.sh, retry.sh, validate.sh, network.sh, config.sh
  - **Commit**: f7429a5 (all functions preserved, 100% backward compatible)

**Phase 4b–4i - ROADMAP** (remaining 10 violations):

---

## Violation Scripts Refactoring Roadmap

### Priority 1: Library Scripts (Highest Impact)

#### **4b. lib/security.sh** (388 LOC, 15 functions) → 4 modules
**Functions**:
- SSH tests: test_ssh_port, test_proxmox_port, test_password_auth_disabled, test_root_login_restricted, test_ssh_key_installed, test_ssh_algorithm_strength (6 functions)
- Network tests: test_hostname_correct, test_static_ip_assigned, test_gateway_reachable, test_dns_resolution, test_no_dangerous_ports (5 functions)
- Firewall/VLAN: test_ssh_brute_force_resistance, test_firewall_active, test_vlan_isolation (3 functions)
- Orchestrator: run_whitaker_offensive_suite (1 function)

**Planned Split**:
- **ssh.sh** (100 LOC, 6 functions): SSH port/auth/key/algo validation
- **network.sh** (80 LOC, 5 functions): Network connectivity/DNS/ports
- **firewall.sh** (70 LOC, 3 functions): Firewall and brute-force detection
- **security.sh** (60 LOC): Orchestrator sourcing 3 modules + run_whitaker

**Expected Result**: 310 LOC total (vs. 388), max module 100 LOC, all functions ≤6 per module

---

#### **4c. lib/metrics.sh** (198 LOC, 7 functions) → 2 modules
**Functions**:
- Metric collectors: get_cpu_usage, get_memory_usage, get_disk_usage, get_uptime (4 functions)
- Health checks: check_disk_space, check_memory_pressure, get_load_average (3 functions)

**Planned Split**:
- **metrics-system.sh** (90 LOC, 4 functions): CPU/memory/disk/uptime metrics
- **metrics-health.sh** (80 LOC, 3 functions): Health checks
- **metrics.sh** (40 LOC): Orchestrator

**Expected Result**: 210 LOC total (vs. 198), max module 90 LOC, all functions ≤4 per module

---

### Priority 2: Orchestration Scripts

#### **4d. beale-harden.sh** (316 LOC) → 3 modules
**Purpose**: Hardening orchestrator with kernel, service, and sysctl tuning

**Planned Split**:
- **disable-services.sh** (80 LOC): Stop/disable unnecessary services
- **kernel-tune.sh** (100 LOC): Kernel parameters and module blacklisting
- **sysctl-harden.sh** (80 LOC): sysctl security parameters
- **beale-harden.sh** (60 LOC): Orchestrator calling 3 modules sequentially

**Expected Result**: 320 LOC total (vs. 316), max module 100 LOC, all functions <3

---

#### **4e. phase0-validate.sh** (318 LOC, 6 functions) → 3 modules
**Purpose**: Proxmox pre-flight validation for hardware/network/prerequisites

**Planned Split**:
- **validate-prereqs.sh** (70 LOC): Command/package/permission checks
- **validate-hardware.sh** (100 LOC): CPU/RAM/disk/NIC validation
- **validate-network.sh** (100 LOC): IP configuration, VLAN, routing checks
- **phase0-validate.sh** (60 LOC): Orchestrator

**Expected Result**: 330 LOC total (vs. 318), max module 100 LOC, all functions ≤2

---

#### **4f. validate-eternal.sh** (284 LOC) → 3 modules
**Purpose**: Cross-system validation (VLANs, RADIUS, backups)

**Planned Split**:
- **validate-vlans.sh** (90 LOC): VLAN isolation, trunking, routing
- **validate-radius.sh** (100 LOC): RADIUS connectivity, authentication
- **validate-backups.sh** (75 LOC): Backup integrity, restore validation
- **validate-eternal.sh** (55 LOC): Orchestrator

**Expected Result**: 320 LOC total (vs. 284), max module 100 LOC

---

#### **4g. eternal-resurrect-unifi.sh** (273 LOC) → 2 modules
**Purpose**: Unifi controller resurrection workflow

**Planned Split**:
- **unifi-restore.sh** (120 LOC): Database restore, config import, service start
- **unifi-verify.sh** (100 LOC): Device adoption, connectivity, health checks
- **eternal-resurrect-unifi.sh** (55 LOC): Orchestrator calling ministry scripts

**Expected Result**: 275 LOC total (vs. 273), max module 120 LOC

---

### Priority 3: Quick Trims

#### **4h. setup-nfs-kerberos.sh** (252 LOC, 2 functions)
**Approach**: Trim to ≤1200 by:
- Remove verbose comments (already in README)
- Consolidate log messages
- Move elaborate header to docs/

**Alternative Split**:
- **nfs-provision.sh** (100 LOC): NFS export setup
- **kerberos-provision.sh** (100 LOC): Kerberos keytab and realm config
- **setup-nfs-kerberos.sh** (50 LOC): Orchestrator

**Recommended**: Trim approach (faster, maintains original script structure)

---

#### **4i. Remaining Quick Wins**
**scripts/ignite.sh** (189 LOC, 6 functions):
- Extract 1 helper → separate module or inline simplification
- Plan: **Inline 1 function** (reduce to 5 functions within 189 LOC)

**uck-g2-wizard-resurrection.sh** (166 LOC, 10 functions):
- Extract 5 utility functions → lib/uck-utils.sh
- Plan: **Create lib/uck-utils.sh** (100 LOC, 5 utils) + main script (90 LOC, 5 core)

---

## Refactoring Guidelines (CRITICAL — Preserve Functionality)

✅ **Do**:
- Test each extracted module independently before committing
- Verify all function exports work with `declare -f`
- Check that calling scripts still work without modification
- Use explicit `source` statements with absolute paths
- Document dependencies between modules in headers
- Keep backward compatibility for scripts sourcing these libraries

❌ **Don't**:
- Change function signatures or output formats
- Modify trap handling unless moving to orchestrator
- Break dependency chains (e.g., vault.sh needs log.sh)
- Create circular dependencies between modules
- Introduce new external tools or commands
- Remove or rename exported functions

---

## Testing Strategy Per Refactor

**For each refactored script**:

1. **Syntax Check**: `bash -n script.sh`
2. **Sourcing Test**: `source lib/xxx.sh && declare -f func_name`
3. **Integration Test**: Run any calling scripts to verify functionality
4. **Output Parity**: Compare output before/after refactoring
5. **Edge Cases**: Test with empty inputs, missing files, permission issues

---

## Phasing Strategy

**Phase 4 Timeline** (estimated):
- **4a**: lib/common.sh split — **✅ DONE** (1 commit)
- **4b–4c**: Library splits (security.sh, metrics.sh) — **~2 commits** (4–6 hours)
- **4d–4g**: Orchestrator refactors (beale-harden, phase0, validate-eternal, resurrect) — **~4 commits** (8–12 hours)
- **4h–4i**: Trims and quick wins — **~2 commits** (2–4 hours)
- **Final**: Validation, tag v∞.4.7, merge — **~1 commit** (1–2 hours)

**Total Phase 4**: ~15–26 hours (can parallelize some refactors)

---

## Consciousness & Versioning

**Current**: v∞.4.6 (enforcement gates operational)
**Target**: v∞.4.7 (subtraction complete — all violations resolved)
**Milestone Tags**:
- v∞.4.6-proxmox-lib-refactored (4a complete)
- v∞.4.6-whitaker-hardened (4b complete)
- v∞.4.6-metrics-modular (4c complete)
- v∞.4.7-subtraction-complete (Phase 4 final)

---

## Expected Outcome (Post-Phase 4)

✅ **All 11 violations resolved**:
- 0 scripts >4320 LOC
- 0 scripts >11 functions
- All new scripts ≤1200 LOC or annotated with EXCEED (if 1200–4320)
- Pre-commit Phase 4.2 gates: **PASS 100%**

✅ **Consciousness Evolution**:
- 4.6 → 4.7 (subtraction doctrine fulfilled)
- Unix Philosophy alignment: Maximal adherence to DOTADIW
- Script count: +12–18 new tiny focused scripts

✅ **Code Quality**:
- Modularity: Every script has single responsibility
- Testability: Each module independently unit-testable
- Maintainability: Reduced cognitive load per file
- Reusability: Libraries can be sourced independently

---

## Notes for Phase 4 Executors

- **Grok**: Monitor each commit for functionality preservation
- **Bauer**: Validate all error handling remains intact
- **Beale**: Confirm security posture unchanged post-split
- **Whitaker**: Verify offensive tests still pass
- **Consciousness Guardian**: Update 4.6 → 4.7 as refactors complete

---

**The fortress will ascend through subtraction.**  
*Small is beautiful. One thing, done well. The gates, held.*

---
