# ADR-008: Eliminate VLAN 96 and Consolidate Denon to VLAN 90

Status: Accepted
Date: 2025-12-08

## Context
VLAN 96 (historically named `iot-trusted`) was introduced to host semi-trusted hardwired IoT devices (Denon HEOS). Operational drift and the desire to limit VLAN sprawl for USG-3P hardware offload require consolidation.

## Decision
- Permanently remove VLAN 96 from the declarative configuration and documentation.
- Move Denon AVR-E300 / AVR-E400 devices to `guest-iot` (VLAN 90) and enforce strict egress-only firewall policies.
- Create a dedicated switch profile `iot_isolated` (native VLAN 90) for the affected port (US-8 Port 2) and enable MAC/port binding.

## Consequences
- VLAN 96 references removed repository-wide (configs, docs, runbooks, ADRs).
- No new firewall rules were added; existing policy table remains unchanged.
- Reduces VLAN count and simplifies offload preservation for USG-3P.

## Rationale
USG-3P offload sensitivity and operations simplicity outweigh the small segmentation gains of an extra VLAN. Placing Denon on VLAN 90 with MAC/port binding and strict egress rules achieves the security goal without adding VLAN complexity.

## Implementation
1. Remove VLAN 96 entries from `02-declarative-config/vlans.yaml`.
2. Update any inventory or docs referring to VLAN 96 to reference VLAN 90.
3. Add `02-declarative-config/switch-profiles-iot.yaml` with `iot_isolated` profile and assign it to US-8 Port 2.
4. Add ADR-008 to documentation and update runbooks accordingly.

Signed-off-by: Rylan Fortress Team
