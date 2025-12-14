# UniFi Bootstrap — Carter Phase
**Initial Controller deployment & device adoption.**

## Execution Order
1. `install-unifi-controller.sh` — Deploy UniFi Network Controller (LXC or bare-metal)
2. `install-unifi.sh` — Install controller on Linux/macOS
3. `adopt_devices.py` / `adopt-devices-wrapper.sh` — Auto-adopt pending APs, switches, gateways
4. `inventory-devices.sh` / `inventory-devices-headless.sh` — List managed devices (SSH or API)

## One-Line Usage
```bash
bash install-unifi-controller.sh
python3 adopt_devices.py --site default
bash inventory-devices.sh
```

## RTO: ~5 min (post-controller boot)
