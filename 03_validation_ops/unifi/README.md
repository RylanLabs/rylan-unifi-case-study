# UniFi Validation Ops — Bauer/Beale Phase
**Runtime verification & isolation audits.**

## Scripts
- `validate-isolation.sh` — Check VLAN segregation (nmap, packet inspection)
- `check-critical-services.sh` — Verify DNS, NTP, DHCP, RADIUS connectivity
- `comprehensive-suite.sh` — Full Beale audit (comprehensive-suite.sh orchestrates)

## One-Line Usage
```bash
CI_MODE=1 bash comprehensive-suite.sh  # Safe in CI
bash validate-isolation.sh --target-vlan 10.0.10.0/26
```

## RTO Validation: <15 min
