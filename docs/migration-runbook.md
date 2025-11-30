# Migration Runbook: Legacy VLAN 1 to Segmented Topology

## Overview
Transition from flat network (VLAN 1) to segmented management, IoT, servers, guest.

## Pre-Migration Checklist
- Controller reachable and devices adopted.
- Backup taken (`backup-cron.sh`).
- Confirm DHCP reservations recorded.

## Steps
1. Dry-run `apply.py` and record planned VLAN creations.
2. Apply VLANs during maintenance window.
3. Update switch port profiles (IoT / Guest isolation tags).
4. Reassign critical static IP devices to new subnets.
5. Apply policy routes & QoS (GUI).
6. Run `validate-isolation.sh`.
7. Monitor logs & metrics for anomalies 24h.

## Rollback
Restore backup archive; revert port profiles to default LAN; flush client DHCP leases.
