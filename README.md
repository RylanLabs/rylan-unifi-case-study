# rylan-unifi-case-study

**Production-grade UniFi network infrastructure with AI-augmented helpdesk**  
*December 2025 deployment – v5.0 stable*

[![CI Validation](https://github.com/T-Rylander/rylan-unifi-case-study/workflows/CI%20Validate/badge.svg)](https://github.com/T-Rylander/rylan-unifi-case-study/actions)

## 🏗️ Architecture Overview

```mermaid
graph TB
    subgraph Internet
        WAN[Cable Modem]
    end
    
    subgraph "Management VLAN 1"
        USG[USG-3P<br/>10.0.1.1<br/>UniFi 8.5.93]
        Switch[UniFi Switch]
    end
    
    subgraph "Server VLAN 10"
        ADDS[Samba AD DC<br/>10.0.10.10<br/>i5 16GB<br/>AD/DNS/NFS/InfluxDB]
        AIWork[AI Workstation<br/>10.0.10.60<br/>2-3x RX 6700 XT<br/>Ollama/Qdrant/Triage]
    end
    
    subgraph "Trusted Devices VLAN 30"
        RPi[Raspberry Pi 5 8GB<br/>10.0.30.40<br/>osTicket + MariaDB]
    end
    
    subgraph "VoIP VLAN 40"
        Phone[IP Phones<br/>EF/DSCP 46]
    end
    
    subgraph "Guest/IoT VLAN 90"
        Guest[Guest Devices<br/>Internet Only]
    end
    
    WAN --> USG
    USG --> Switch
    Switch --> ADDS
    Switch --> AIWork
    Switch --> RPi
    Switch --> Phone
    Switch --> Guest
    
    AIWork -.HTTP API.-> RPi
    RPi -.Ticket Events.-> AIWork
    ADDS -.Auth/DNS.-> AIWork
    ADDS -.Auth/DNS.-> RPi
```

    ### Full Diagram Source
    See `docs/architecture-v5.mmd` and render with Mermaid Live or VS Code extensions.

## 🎯 Key Features

- **Zero-Trust Network Isolation**: Policy Table v5 with <15 rules (vs 200+ firewall rules)
- **Hardware Offload Preserved**: All inter-VLAN routing hardware-accelerated
- **AI Ticket Triage**: Llama 3.3 70B with 93%+ confidence auto-close
- **PII Redaction**: Presidio scrubbing before Ollama ingestion
- **Declarative Everything**: Git-controlled VLANs, policy rules, QoS
- **CI/CD Validation**: Automated rule count checks, dry-run applies

## 📁 Repository Structure

```
rylan-unifi-case-study/
├── 01-bootstrap/                  # Initial setup scripts
│   ├── install-unifi.ps1         # Windows/PowerShell installer
│   ├── install-unifi.sh          # Linux/Bash installer
│   └── adopt-devices.py          # Automated device adoption
├── 02-declarative-config/        # Network configuration as code
│   ├── vlans.yaml                # VLAN definitions
│   ├── policy-table-rylan-v5.json # Zero-trust policy rules
│   ├── config.gateway.json       # USG VoIP QoS config
│   └── apply.py                  # Idempotent config applicator
├── 03-ai-helpdesk/               # AI-augmented support system
│   └── triage-engine/
│       ├── main.py               # FastAPI triage service
│       ├── Dockerfile            # <120 MB container
│       └── requirements.txt
├── shared/
│   └── inventory.yaml            # Single source of truth for IPs
├── docs/
│   └── architecture-v5.mmd       # Mermaid diagram source
├── .github/
│   └── workflows/
│       └── ci-validate.yaml      # CI validation pipeline
├── requirements.txt              # Python dependencies
├── pyproject.toml                # Project metadata
├── .pre-commit-config.yaml       # Git hooks
├── .gitignore
├── README.md                     # This file
└── ROADMAP.md                    # ADRs and version history
```

## 🚀 Quick Start

## ⚡ Quick Ignite (Post-Bootstrap)

**One-command deployment sequence:**

```bash
# Clone and enter repository
git clone https://github.com/T-Rylander/rylan-unifi-case-study.git
cd rylan-unifi-case-study

# Activate environment and install dependencies
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -e .

# Run ignite orchestrator
bash scripts/ignite.sh
```

**Ignite phases:**
1. **Bootstrap**: UniFi controller installation (Ubuntu 24.04)
2. **Declarative Config**: Dry-run → Apply VLANs/policies/QoS
3. **Validation**: Isolation checks + service health

**Status:**
- AI Helpdesk: ✅ 100% (triage engine operational)
- Packaging: ✅ 100% (editable install + deps)
- IaC: 🟡 Partial (manual policy/QoS GUI apply fallback)

### Prerequisites

**All Platforms:**
- Python 3.11+
- Git
- Network access to UniFi Controller (local admin, no 2FA)

**Windows (PowerShell):**
```powershell
# Install Python dependencies
python -m pip install -r requirements.txt

# Bootstrap UniFi (if needed)
.\01-bootstrap\install-unifi.ps1 -ControllerIP "10.0.1.1"
```

**Linux/macOS (Bash):**
```bash
# Install Python dependencies
pip3 install -r requirements.txt

# Bootstrap UniFi (if needed)
bash 01-bootstrap/install-unifi.sh
```

### Deploy Network Configuration

```bash
# Dry-run validation (always run first)
python 02-declarative-config/apply.py --dry-run

# Apply to production (requires confirmation)
python 02-declarative-config/apply.py --apply

# Apply specific components
python 02-declarative-config/apply.py --vlans-only
python 02-declarative-config/apply.py --policy-only
```

### Deploy AI Triage Engine

```bash
# On AI Workstation (10.0.10.60)
cd 03-ai-helpdesk/triage-engine

# Build container
docker build -t triage-engine:v5 .

# Run with Ollama backend
docker run -d \
  -p 8000:8000 \
  -e OLLAMA_HOST=http://localhost:11434 \
  -e OSTICKET_URL=http://10.0.30.40 \
  -e AUTO_CLOSE_THRESHOLD=0.93 \
  --name triage-engine \
  triage-engine:v5

# Verify health
curl http://10.0.10.60:8000/health

### osTicket Webhook → Triage
- Install `03-ai-helpdesk/osticket-webhook.php` into osTicket plugins directory.
- Configure API URL `http://10.0.10.60:8000/triage` and API key in `shared/inventory.yaml`.
```

## 🔒 Security Architecture

### Network Isolation (Policy Table v5)

**Why Policy Table over Firewall Rules?**
- **14 rules vs 200+**: Dramatic simplification
- **Hardware offload preserved**: USG-3P processes at line rate
- **Predictable behavior**: Single decision point per flow
- **Version controlled**: JSON diff shows exact changes
- **Audit friendly**: Complete policy visibility in one file

See `ROADMAP.md` for full ADR.

### PII Protection

All ticket data passes through Presidio before Ollama:
- Credit cards: REDACTED_CC
- SSN: REDACTED_SSN
- Emails: REDACTED_EMAIL
- Phone numbers: REDACTED_PHONE

### VLANs

| VLAN | Name            | Subnet         | Gateway     | Purpose                  |
|------|-----------------|----------------|-------------|--------------------------|
| 1    | Management      | 10.0.1.0/27    | 10.0.1.1    | UniFi devices + controller |
| 10   | servers         | 10.0.10.0/26   | 10.0.10.1   | Infrastructure           |
| 30   | trusted-devices | 10.0.30.0/24   | 10.0.30.1   | Workstations + osTicket  |
| 40   | voip            | 10.0.40.0/27   | 10.0.40.1   | VoIP only                |
| 90   | guest-iot       | 10.0.90.0/25   | 10.0.90.1   | Guest + IoT              |

## rylan-dc – Eternal Multi-Role Server

| Role                        | IP          | VLAN | Notes                              |
|-----------------------------|-------------|------|------------------------------------|
| Samba AD/DC + DNS + NFS     | 10.0.10.10  | 10   | Primary interface                  |
| Lightweight proxyDHCP + PXE | 10.0.30.10  | 30   | eno1.30 VLAN sub-interface         |
| UniFi Controller            | 10.0.10.20  | 10   | docker macvlan (inform now 8081)   |

```mermaid
graph LR
    eno1["eno1 (VLAN 10, 10.0.10.10)"] --> eno1_30["eno1.30 (VLAN 30, 10.0.30.10)"]
```

Note: osTicket remains on `10.0.30.40` in `trusted-devices` (VLAN 30).

## 🤝 Contributing

This is a production system. Changes require:
1. ADR in `ROADMAP.md`
2. Passing CI (`ci-validate.yaml`)
3. Dry-run validation in staging
4. Change window approval

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- **UniFi Policy Table**: Credit to Ubiquiti for superior architecture over stateful firewall rules
- **Ollama**: Best-in-class local LLM deployment
- **Presidio**: Microsoft's PII detection engine

---

**Production Status**: ✅ Stable (v5.0)  
**Last Updated**: December 2025  
**Maintained by**: hellodeolu-era systems architecture team

## 📌 Current Real Status vs Roadmap

**Implemented (Git-controlled):**
- Bootstrap: controller install, device adoption, VLAN stubs
- Declarative VLANs: `vlans.yaml` reconciled via new `apply.py`
- Zero-Trust Definitions: `policy-table.yaml` (manual GUI apply)
- QoS Smart Queue Spec: `qos-smartqueue.yaml` (manual GUI apply)
- AI Helpdesk: triage engine + webhook, unit tests
- Shared Utilities: `shared/auth.py`, `shared/unifi_client.py`
- Ops Tooling: isolation + SIP health + backup scripts
- Docs: ADR, migration runbook, DR drill, operations guide, troubleshooting

**Pending / Manual Steps:**
- Policy route API automation (future endpoint research)
- Smart Queue DSCP EF application (controller UI)
- CI workflow for validation-ops (`validate-isolation.sh`, `phone-reg-test.py`)
- Periodic backup verification in pipeline

## 🔧 Validation & Ops

Run isolation checks:
```bash
bash 03-validation-ops/validate-isolation.sh
```

Check SIP registrations (placeholder API expected):
```bash
python 03-validation-ops/phone-reg-test.py
```

Create backups (invoke or schedule):
```bash
BACKUP_DEST=/var/backups/rylan bash 03-validation-ops/backup-cron.sh
```

## 🚀 Ignite Sequence (Manual Orchestration)
```bash
# 1. Bootstrap (if fresh host)
bash 01-bootstrap/install-unifi-controller.sh
python 01-bootstrap/adopt-devices.py

# 2. Declarative apply (dry-run then apply)
python 02-declarative-config/apply.py --dry-run
python 02-declarative-config/apply.py

# 3. GUI tasks
#   - Policy Routes: replicate policy-table.yaml
#   - QoS Smart Queue: replicate qos-smartqueue.yaml

# 4. Validation
bash 03-validation-ops/validate-isolation.sh
python 03-validation-ops/phone-reg-test.py

# 5. Backup
BACKUP_DEST=/var/backups/rylan bash 03-validation-ops/backup-cron.sh
```

#   C I   c a c h e   r e f r e s h 
 
 