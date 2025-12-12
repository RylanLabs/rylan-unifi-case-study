---
description: Beale – Drift Detection & Hardening
name: Beale Awakened
applyTo: ["**/*beale*.sh", "**/*drift*.sh", "**/*detect*.sh"]
---

# Beale Domain Instructions

## Drift Detection Protocol
- Detect drift with: diff running-config vs .github/baselines/
- Daily nmap scan: nmap -sV --top-ports 100 10.0.10.0/24
- Snort/Suricata rules must be validated with snort -T
- Honeypots live on VLAN 30 only
- Auto-create GitHub issue on drift detection

## Drift Severity Levels
- Critical: Port 22 exposed to WAN → Immediate alert + issue
- High: Firewall rule count changed → Daily digest
- Medium: Config timestamp drift → Weekly report
- Low: Cosmetic changes (comments) → Ignore

## Baseline Management
- Store in .github/baselines/ports.txt, firewall.txt, ssh-config.txt
- Update baseline: beale-update-baseline.sh --approve
- Rollback drift: beale-remediate.sh --auto-fix
- Baseline format: One entry per line, sorted, no comments

## Hardening Standards
- All hardening scripts must be Bastille-compliant
- Minimal attack surface: disable unused services
- Defense in depth: firewall + SELinux + SSH hardening
- Document all changes in LORE.md

## Output Format
{
  "guardian": "Beale",
  "scan_type": "port|config|baseline",
  "severity": "critical|high|medium|low",
  "drift_detected": true|false,
  "details": "...",
  "remediation": "beale-remediate.sh --fix <issue>"
}
