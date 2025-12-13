# 02-declarative-config — Desired State Definitions

**Purpose**: YAML-defined network configuration (VLANs, firewall rules, QoS, switch profiles).
**Estimated Time**: <30s to apply
**Risk Level**: Medium (network changes)

## Overview

This directory contains the **desired state** for the UniFi network. All changes are:
1. Defined in YAML (human-readable)
2. Converted to JSON (API format)
3. Applied via `apply.py` or `apply-wrapper.sh`
4. Validated by Bauer (nmap isolation tests)

## File Index

| File | Purpose | Schema |
|------|---------|--------|
| `vlans.yaml` | VLAN definitions (5 segments) | id, name, subnet, dhcp |
| `firewall-rules.yaml` | Inter-VLAN firewall rules (≤10) | src, dst, port, action |
| `policy-table.yaml` | Master policy reference | All rules consolidated |
| `qos-smartqueue.yaml` | QoS/SmartQueue config | bandwidth, priority |
| `switch-profiles.yaml` | Port profiles (trunk, access) | ports, vlans, poe |
| `switch-profiles-iot.yaml` | IoT-specific port config | isolation rules |
| `config.gateway.json` | USG config export | Full gateway state |

## Configuration Flow

```mermaid
flowchart LR
    subgraph DEFINE["1️⃣ Define"]
        YAML[vlans.yaml<br>firewall-rules.yaml]
    end

    subgraph CONVERT["2️⃣ Convert"]
        YAML --> Apply[apply.py]
        Apply --> JSON[JSON payload]
    end

    subgraph PUSH["3️⃣ Push"]
        JSON --> API[UniFi API<br>/api/s/default/...]
        API --> Controller[UniFi Controller]
    end

    subgraph VALIDATE["4️⃣ Validate"]
        Controller --> Bauer[🛡️ Bauer<br>nmap isolation test]
        Bauer -->|Pass| Done([✅ Config Active])
        Bauer -->|Fail| Rollback[./rollback.sh]
        Rollback --> YAML
    end

    style YAML fill:#036,stroke:#0af,color:#fff
    style Done fill:#030,stroke:#0f0,color:#fff
    style Rollback fill:#600,stroke:#f00,color:#fff
```text

## Usage

### Apply Configuration

```bash
# Full apply (all YAML files)
./02-declarative-config/apply-wrapper.sh

# Or via Python directly
python3 ./02-declarative-config/apply.py --config vlans.yaml

# Dry run (preview changes)
python3 ./02-declarative-config/apply.py --config vlans.yaml --dry-run
```text

### Validate After Apply

```bash
# Bauer VLAN isolation check
./scripts/validate-isolation.sh

# Expected: 9/9 tests passed
```text

### Rollback

```bash
# Restore from .backup files
cp vlans.yaml.backup vlans.yaml
./02-declarative-config/apply-wrapper.sh
```text

## VLAN Architecture

| VLAN ID | Name | Subnet | Purpose |
|---------|------|--------|---------|
| 1 | Default | 192.168.1.0/24 | Legacy/Untagged |
| 10 | Management | 10.0.10.0/24 | Network devices, SSH |
| 20 | Servers | 10.0.20.0/24 | Production servers |
| 30 | Trusted | 10.0.30.0/24 | Workstations, printers |
| 40 | VoIP | 10.0.40.0/24 | Phones, SIP |
| 50 | Guest | 10.0.50.0/24 | Isolated guest access |

## Firewall Rules (≤10, Hardware Offload Safe)

```yaml
# Example from firewall-rules.yaml
- name: Block IoT to Mgmt SSH
  src: 10.0.40.0/24
  dst: 10.0.10.0/24
  port: 22
  action: DROP

- name: Allow VoIP to SIP
  src: 10.0.40.0/24
  dst: 10.0.20.20
  port: 5060
  action: ACCEPT
```text

**Constraint**: ≤10 total rules (hardware offload requirement).

## Related

- [03-validation-ops/validate-isolation.sh](../03-validation-ops/validate-isolation.sh) — VLAN tests
- [05-network-migration/](../05-network-migration/) — Migration scripts
- [policy-table.yaml](policy-table.yaml) — Master policy reference
