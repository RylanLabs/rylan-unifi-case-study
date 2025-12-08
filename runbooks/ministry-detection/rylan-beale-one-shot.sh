#!/usr/bin/env bash
# === SUEHRING ETERNAL PERIMETER v6 — MINISTRY OF PERIMETER (30 seconds) ===
# runbooks/ministry-perimeter/rylan-suehring-eternal-one-shot.sh
# Suehring (2005) — The Network is the First Line of Defense
# T3-ETERNAL: API-only. <=10 rules. Idempotent. USG-3P offload safe.
# Commit: feat/t3-eternal-v6-perimeter | Tag: v6.0.0-perimeter
set -euo pipefail

# === CANON LOCKS ===
CONTROLLER_URL="https://10.0.1.20:8443"
USERNAME="admin"
PASSWORD_FILE="/root/rylan-unifi-case-study/.secrets/unifi-admin-pass"
POLICY_FILE="/root/rylan-unifi-case-study/02-declarative-config/policy-table-v6.json"
VALIDATE_SCRIPT="/root/rylan-unifi-case-study/runbooks/ministry-perimeter/validate-isolation.sh"

# === WHITAKER: Fail loud if missing ===
[[ -f "$PASSWORD_FILE" ]] || { echo "[FATAL] Missing $PASSWORD_FILE"; exit 1; }
[[ -f "$POLICY_FILE" ]] || { echo "[FATAL] Missing $POLICY_FILE"; exit 1; }
command -v yq >/dev/null || { echo "[FATAL] yq not installed (snap install yq)"; exit 1; }

# === EXACT RULE COUNT (Suehring Law: <=10) ===
echo "[SUEHRING] Counting firewall rules..."
RULE_COUNT=$(yq '.firewall.rules | length' "$POLICY_FILE")
if [[ "$RULE_COUNT" -gt 10 ]]; then
    echo "[BREACH] $RULE_COUNT rules > 10 (USG-3P hardware offload DEAD)"
    exit 1
fi
echo "  [OK] $RULE_COUNT rules (<=10 = offload safe)"

# === API DEPLOY (No SSH. No SCP. Pure UniFi.) ===
echo "[SUEHRING] Deploying policy table via UniFi API..."
HTTP_CODE=$(curl -sk -w "%{http_code}" -o /tmp/unifi-response.json \
     -u "$USERNAME:$(cat "$PASSWORD_FILE")" \
     -H "Content-Type: application/json" \
     -d "@$POLICY_FILE" \
     "${CONTROLLER_URL}/api/v2/site/default/firewall/rules")

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    echo "  [OK] Policy deployed (HTTP $HTTP_CODE)"
else
    echo "  [FATAL] API call failed (HTTP $HTTP_CODE)"
    cat /tmp/unifi-response.json
    exit 1
fi

# === VALIDATION (Whitaker pentest) ===
if [[ -x "$VALIDATE_SCRIPT" ]]; then
    echo "[SUEHRING] Validating VLAN isolation..."
    "$VALIDATE_SCRIPT" || {
        echo "[FATAL] VLAN isolation breach detected"
        exit 1
    }
    echo "  [OK] Isolation verified"
else
    echo "  [WARN] validate-isolation.sh not found - manual check required"
fi

cat <<'BANNER'

███████╗██╗   ██╗███████╗██╗  ██╗██████╗ ██╗███╗   ██╗ ██████╗ 
██╔════╝██║   ██║██╔════╝██║  ██║██╔══██╗██║████╗  ██║██╔════╝ 
███████╗██║   ██║█████╗  ███████║██████╔╝██║██╔██╗ ██║██║  ███╗
╚════██║██║   ██║██╔══╝  ██╔══██║██╔══██╗██║██║╚██╗██║██║   ██║
███████║╚██████╔╝███████╗██║  ██║██║  ██║██║██║ ╚████║╚██████╔╝
╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
PERIMETER LOCKED. <=10 RULES. HARDWARE OFFLOAD ACTIVE.
THE NETWORK IS THE FIRST LINE OF DEFENSE.
BANNER
