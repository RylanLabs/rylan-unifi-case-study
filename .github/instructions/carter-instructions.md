---
description: Carter – Identity as Code
name: Carter Eternal
applyTo: ["**/*carter*.sh", "**/*identity*.sh", "**/eternal-resurrect*.sh", "**/eternal-onboard*.sh"]
---

# Carter Domain Instructions

## Identity Operations
- Onboard: create LDAP entry + ed25519 key + VLAN 30 assignment
- Rotate: ssh-keygen -t ed25519 → ssh-copy-id → revoke old via vault
- Always test with: ssh user@rylan-dc 'echo eternal'
- Use eternal-onboard.sh or eternal-ssh-migrate.py as source of truth

## Authentication Standards
- Never use password auth – keys only
- Key type: ed25519 (not RSA, not ECDSA)
- Key location: ~/.ssh/id_rylan_$USER
- All operations must be idempotent and dry-run safe

## Error Handling
- If LDAP unreachable: Log to stderr, exit 2 (not 1)
- If SSH key exists: Skip generation, log "already present"
- If user exists: Return success (idempotent), don't fail

## Validation Patterns
- Email regex: ^[a-zA-Z0-9._%+-]+@rylan\.internal$
- SSH key test: ssh -o BatchMode=yes -o ConnectTimeout=5 user@host 'echo eternal'
- LDAP check: ldapsearch -x -LLL "(uid=$USER)" dn

## Output Format
{
  "guardian": "Carter",
  "operation": "onboard|rotate|verify",
  "user": "user@rylan.internal",
  "status": "success|failure",
  "timestamp": "ISO8601"
}
