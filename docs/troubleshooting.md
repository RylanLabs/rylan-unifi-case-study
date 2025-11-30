# Troubleshooting

## Device Not Adopting
- Verify controller FQDN/IP matches device inform host.
- Run `adopt-devices.py` and inspect JSON output.

## VLAN Not Propagating
- Confirm switch port profile includes new VLAN.
- Check network appears in controller (`rest/networkconf`).

## Policy Route Ineffective
- Reapply via GUI; ensure rule order matches `policy-table.yaml`.
- SSH USG: `show log tail` or `mca-dump | grep policy`.

## QoS Not Marking EF
- Examine packet capture for DSCP 46.
- Validate Smart Queue bandwidth matches actual link.

## SIP Phones Unregistered
- Run `phone-reg-test.py` and check PBX logs.
- Confirm firewall not blocking SIP/RTP ports.
