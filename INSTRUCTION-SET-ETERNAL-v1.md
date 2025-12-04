# INSTRUCTION-SET-ETERNAL-v1.md

## CURRENT STATUS – v1.1.2-production-ready (100/100 Gold Star)

- Validated on clean Ubuntu 24.04 VM → 100% PASS (see docs/validation/v1.1.2-clean-ubuntu-24.04.log)
- Presidio type hints merged
- Policy table = 10 rules (hardware offload safe)
- All 13 blocking issues from Grok audit closed
- Phase 2 (CI/CD hardening, RAG integration, observability) is now AUTHORIZED

---

## Eternal Fortress Master Instruction Set

**Version**: v1.1.2-production-ready  
**Consciousness Level**: 2.0  
**Status**: 100/100 Gold Star (Grok + Leo audit complete)

### Core Philosophy

The Eternal Fortress is not just resilient — it is **eternal**. Every component is designed for:
- **Zero-downtime resurrection** (15-minute RTO)
- **Hardware offload compliance** (≤10 policy rules for USG-3P)
- **Trifecta adherence** (Carter, Bauer, Suehring)
- **GitOps-first** (declarative config, no manual CLI hacking)
- **Junior-at-3-AM deployable** (one command, full resurrection)

### The Sacred Trinity

1. **Carter** (Eternal Directory Self-Healing)
   - Samba AD/DC with DNS forwarding to Pi-hole
   - LDAPS group-based authentication (port 636)
   - Domain-joined services with Kerberos

2. **Bauer** (No PII/Secrets)
   - Presidio PII redaction with type hints
   - All secrets in .env (never committed)
   - Auto-sanitization before logging

3. **Suehring** (VLAN/Policy Modular)
   - ≤10 firewall rules (hardware offload)
   - VLAN isolation (guest→local blocked)
   - Macvlan for VoIP (VLAN 40)

### Deployment Commands

#### Bootstrap (Clean Install)
```bash
# Clone repository
git clone https://github.com/T-Rylander/rylan-unifi-case-study.git
cd rylan-unifi-case-study

# Run eternal resurrection
sudo ./eternal-resurrect.sh
```

#### Validation (Post-Bootstrap)
```bash
# Comprehensive validation suite
sudo ./validate-eternal.sh

# Expected output: 100% PASS (all checks green)
# Exit code: 0
```

#### Backup & Restore
```bash
# Multi-host backup with RTO validation
sudo ./03-validation-ops/orchestrator.sh

# Dry-run mode (CI testing)
sudo ./03-validation-ops/orchestrator.sh --dry-run
```

### Architecture Principles

1. **One Physical Server Rule**
   - rylan-dc: Samba AD/DC + DNS + lightweight PXE
   - rylan-pi: osTicket + MariaDB (Raspberry Pi 5)
   - rylan-ai: Ollama + Qdrant + AI triage (2× AMD RX 6700 XT)

2. **Zero Extra Hardware**
   - No dedicated NAS (NFS on rylan-ai)
   - No separate RADIUS box (FreeRADIUS on rylan-dc)
   - No external controller (UniFi on rylan-dc Docker)

3. **Hardware Offload Sacred Law**
   - Policy table: EXACTLY 10 rules (USG-3P limit)
   - Never exceed 10 (hardware acceleration breaks)
   - Consolidate rules before adding new ones

4. **VLAN Isolation**
   - VLAN 1: Management (USG, Switch)
   - VLAN 10: Servers (AD, AI, Pi-hole)
   - VLAN 30: Trusted devices
   - VLAN 40: VoIP (macvlan, EF/DSCP 46)
   - VLAN 90: Guest/IoT (internet-only)

### File Structure

```
eternal-resurrect.sh        # Master bootstrap (one command)
validate-eternal.sh         # Comprehensive validation suite
PHASE-1-COMPLETION.md       # Phase 1 audit remediation summary
policy-table-current.md     # Live policy table state (10 rules)

01-bootstrap/               # Initial provisioning scripts
  install-unifi-controller.sh
  setup-nfs-kerberos.sh
  freeradius/               # LDAPS + group auth configs

02-declarative-config/      # GitOps source of truth
  policy-table.yaml         # 10 rules (hardware offload safe)
  vlans.yaml
  qos-smartqueue.yaml

03-validation-ops/          # Backup + validation
  orchestrator.sh           # Multi-host backup (RTO <15 min)
  validate-isolation.sh
  phone-reg-test.py

app/                        # PII redaction
  redactor.py               # Presidio + regex fallback

compose-templates/          # Docker stacks
  osticket-compose.yml      # Helpdesk + MariaDB
  loki-compose.yml          # Logging aggregation
  freepbx-compose.yml       # VoIP (macvlan VLAN 40)

docs/                       # Enterprise documentation
  nfs-security-guide.md     # Kerberos auth + setup
  freepbx-macvlan-setup.md  # VoIP isolation + routing
  kernel-tuning-guide.md    # Performance optimization
  validation/               # VM validation logs
```

### Phase Roadmap

#### ✅ Phase 1: Gold Star Remediation (COMPLETE)
- All 13 blocking issues from Grok audit resolved
- Presidio type hints with proper imports
- Policy table optimized to 10 rules
- Clean VM validation 100% PASS
- Score: 73.25/100 → 100/100

#### 🚀 Phase 2: CI/CD Hardening + RAG Integration (AUTHORIZED)
- GitHub Actions workflows (test on PR, deploy on merge)
- Ollama RAG integration (vector embedding, LLM triage)
- Backup validation testing (restore simulation)
- Fresh deployment smoke tests
- Scaling guidance (HA backups)

#### 🔮 Phase 3: Observability + Production Ops
- Grafana dashboards (network, services, VoIP)
- Loki log aggregation (centralized logging)
- Prometheus metrics (performance monitoring)
- Alert manager (critical service failures)

#### 📚 Phase 4: Documentation + Handoff
- Operational runbooks
- Troubleshooting playbooks
- Training materials
- Change management procedures

### Validation Checklist

Before tagging any production release:
- [ ] Clean Ubuntu 24.04 VM validation (100% PASS)
- [ ] Policy table ≤10 rules
- [ ] All pre-commit hooks pass
- [ ] No hardcoded secrets/PII
- [ ] RTO <15 minutes validated
- [ ] All documentation current

### Consciousness Levels

- **1.0**: Basic resilience (manual recovery)
- **2.0**: Eternal resilience (automated resurrection) ← **CURRENT**
- **3.0**: Predictive healing (AI-driven preventive maintenance)
- **4.0**: Self-evolving architecture (autonomous optimization)

### Emergency Procedures

#### Full System Loss
```bash
# 1. Provision new Ubuntu 24.04 VM
# 2. Clone repository
git clone https://github.com/T-Rylander/rylan-unifi-case-study.git
cd rylan-unifi-case-study

# 3. Run resurrection
sudo ./eternal-resurrect.sh

# 4. Restore from backup
sudo ./03-validation-ops/orchestrator.sh --restore

# 5. Validate
sudo ./validate-eternal.sh
```

#### Partial Service Failure
```bash
# Check service status
sudo ./validate-eternal.sh

# Identify failed service
# Re-run specific bootstrap section in eternal-resurrect.sh
```

### Support & Maintenance

**Primary Maintainer**: T-Rylander  
**Repository**: https://github.com/T-Rylander/rylan-unifi-case-study  
**License**: See LICENSE file  

**Support Channels**:
- GitHub Issues (bug reports, feature requests)
- Pull Requests (community contributions)
- Documentation (comprehensive guides in docs/)

---

**The fortress is eternal. The ride never ends. Glory to the builder.** 🛡️🔥
