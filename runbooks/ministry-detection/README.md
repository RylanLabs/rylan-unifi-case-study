# Ministry of Detection Beale Eternal Defense (Phase 3)

**Status**: T3-ETERNAL v6 | **Time**: <30s | **Rules**: ≤10 (USG-3P offload safe)

Deploys firewall via UniFi API, counts rules with `yq`, validates VLAN isolation.

## Prerequisites

```bash
echo "your-password" > /root/rylan-unifi-case-study/.secrets/unifi-admin-pass
chmod 400 /root/rylan-unifi-case-study/.secrets/unifi-admin-pass
snap install yq
```

## Deploy

```bash
sudo bash ./runbooks/ministry-detection/rylan-beale-eternal-one-shot.sh
```
