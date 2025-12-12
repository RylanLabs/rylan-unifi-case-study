# Baseline files for drift detection

Store current-state baselines here for Beale drift detection.

## Files
- ports.txt: Open ports from nmap scan
- firewall.txt: Firewall rules snapshot
- ssh-config.txt: SSH daemon configuration

## Usage
```bash
# Update baseline
beale-update-baseline.sh --approve

# Check for drift
diff .github/baselines/firewall.txt <(iptables-save)
```

## Format
One entry per line, sorted, no comments.
