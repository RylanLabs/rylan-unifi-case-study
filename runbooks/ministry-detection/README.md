# Ministry of Detection  Beale Eternal

**Status**: T3-ETERNAL v6 | **Time**: <120s | **Modules**: Snort IDS + Wazuh Agent

Detection is the first line of defense. Deploys Snort IDS with eternal ruleset, registers Wazuh agent, optional Cowrie honeypot.

## Prerequisites

`bash
# Generate Wazuh API key vault
echo "your-wazuh-api-key" > /root/rylan-unifi-case-study/.secrets/wazuh-api-key
chmod 400 /root/rylan-unifi-case-study/.secrets/wazuh-api-key

# Ensure Snort + Wazuh installed
apt-get install -y snort wazuh-agent
`

## Deploy

`bash
sudo bash ./runbooks/ministry-detection/rylan-beale-eternal-one-shot.sh
`

## Validation

`bash
# Check Snort running
systemctl status snort

# Verify Wazuh agent connected
/var/ossec/bin/agent_control -l
`

**Beale has risen. The fortress watches eternal.**
