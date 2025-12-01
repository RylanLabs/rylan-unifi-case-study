# rylan-unifi-case-study — Eternal Green v5.1 🟢

**One physical server. Zero extra hardware. Full AD, PXE boot, UniFi Controller, zero-trust — forever.**

A fully GitOps-driven, production-grade, single-server network stack that runs Samba AD/DC, lightweight PXE, and UniFi Controller on the same box — with zero-trust isolation, USG-3P hardware offload safe, and junior-at-3AM deployable.

**ETERNAL GREEN v5.1 achieved November 2025** — merged, verified, immortal.

## Table of Contents
- [About](#about)
- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## About

This repository is the **canonical, version-controlled source of truth** for the entire Rylan Labs internal network.

It implements a complete zero-trust L3-isolated network on a single USG-3P + USW-Lite-8-PoE + one physical server (`rylan-dc`) that simultaneously runs:

- Samba Active Directory Domain Controller (DNS, Kerberos, LDAP, NFS)
- UniFi Network Controller (Docker + macvlan)
- Lightweight proxy-DHCP + PXE boot server for trusted laptops (VLAN 30)
- Full inter-VLAN isolation with only 8 explicit allow rules (USG-3P offload safe forever)

Everything is declarative, reproducible, and documented to survive firmware upgrades, junior engineers at 3 AM, and the heat death of the universe.

## Installation

# 1. Clone the repo
git clone https://github.com/T-Rylander/rylan-unifi-case-study.git
cd rylan-unifi-case-study

# 2. Review and apply (rylan-dc only)
#    → See docs/runbooks/ for full deployment sequence
All configuration lives under bootstrap/ and 02-declarative-config/.
Apply via the provided runbooks — no manual GUI clicks required.
Usage

Ensure switch port to rylan-dc is trunk (Native VLAN 10 + tagged VLAN 30)
→ See docs/runbooks/switch-port-rylan-dc.md
Deploy netplan + PXE service
→ One-click script coming soon™ (or follow runbook)
Boot any laptop on VLAN 30 → PXE → iPXE menu → domain join works automatically
UniFi devices remain adopted (inform now on port 8081)

Features

Single-server multi-role — Samba AD, PXE, UniFi Controller on one box
Zero DHCP conflicts — dnsmasq runs in proxy-DHCP mode only
True zero-trust — Network Isolation + only 8 explicit allow rules
USG-3P hardware offload safe forever (≤15 rules)
VLAN sub-interface — eno1.30 gives PXE its own IP (10.0.30.10) without extra NICs
Full GitOps — every firewall rule, VLAN, and config is code
ETERNAL GREEN — CI passes, lint clean, Unicode-free, ready for 2030

Contributing
Contributions are welcome and will be eternally green!

Fork the repository
Create a feature branch (git checkout -b feature/amazing-thing)
Commit your changes (git commit -m 'feat: amazing thing')
Push and open a Pull Request

All YAML will be linted. All rules must stay ≤15. Eternal green is non-negotiable.
License
This project is licensed under the MIT License - see the LICENSE file for details.
Contact
Maintainer: T. Rylander
Project Link: https://github.com/T-Rylander/rylan-unifi-case-study
ETERNAL GREEN v5.1 — Locked, loaded, and never going back. 🟢
