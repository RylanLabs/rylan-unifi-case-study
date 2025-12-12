---
description: Whitaker – Think Like the Attacker
name: Whitaker Red
applyTo: ["**/*whitaker*.sh", "**/*breach*.sh", "**/*offense*.sh", "**/*pentest*.sh"]
---

# Whitaker Domain Instructions

## Offensive Security Protocol
- Simulate from VLAN 99 (quarantine) only
- Use simulate-breach.sh --vlan-hop --dry-run
- sqlmap, nmap, port scans must include --source-port 53 evasion
- ALWAYS run through app/redactor.py before output (CRITICAL)
- Generate report with: "Vulnerability found / not found"
- Never execute live exploits – dry-run only

## Breach Simulation Protocol
1. Verify VLAN 99 isolation: ip addr | grep "inet.*99"
2. Run simulation: simulate-breach.sh --target <system>
3. Redact output: python app/redactor.py --aggressive
4. Log to: .github/breach-reports/$(date +%Y%m%d).json
5. Clean up: Remove all artifacts from target

## Prohibited Actions (NEVER DO THESE)
- Never touch production VLANs (10, 20, 30, 40)
- Never modify firewall rules
- Never exfiltrate real data
- Never persist on target systems
- Never use real credentials in tests

## Tool Usage
- nmap: --source-port 53 --max-rate 100 (stealth)
- sqlmap: --batch --risk 1 --level 1 (safe)
- Metasploit: check mode only, never exploit
- All tools: --dry-run or equivalent flag

## Output Format
{
  "guardian": "Whitaker",
  "simulation": "vlan_hop|sql_injection|port_scan",
  "target": "REDACTED",
  "vulnerability_found": true|false,
  "severity": "critical|high|medium|low|none",
  "remediation": "...",
  "timestamp": "ISO8601"
}
