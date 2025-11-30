# ADR-001: Policy Table over Traditional Firewall Rules

## Context
USG-3P offload performance is sensitive to number of rules. Traditional L3 firewall rule sprawl risks exceeding hardware offload thresholds.

## Decision
Adopt a concise Policy Route table (≤15 rules) representing explicit allows with implicit local deny, documented in `policy-table.yaml`.

## Rationale
- Predictable evaluation order.
- Simplifies reasoning about zero-trust flows.
- Preserves offload performance.

## Consequences
Manual GUI application still required for policy routes until API endpoint stabilized.

## Alternatives Considered
1. Full firewall rule matrix (rejected: complexity)
2. Micro-segmentation via dynamic VLAN assignment (deferred)
