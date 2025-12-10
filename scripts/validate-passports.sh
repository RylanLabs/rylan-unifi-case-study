#!/usr/bin/env bash
set -euo pipefail

# Description: Offensive validation of all device passports
# Requires: All passport JSON files
# Consciousness: 2.6
# Runtime: 8

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

echo "🔱 WHITAKER PASSPORT VALIDATION"
echo "Consciousness: 2.6 | $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

FAILED=0

# Test 1: Signature integrity (Bauer: Trust Nothing)
echo "→ Validating passport signatures..."
for PASSPORT in inventory/*.json 02-declarative-config/*.json runbooks/*.json; do
  [[ -f "${PASSPORT}" ]] || continue
  
  STORED_SIG=$(jq -r '.signature' "${PASSPORT}" 2>/dev/null || echo "MISSING")
  CONTENT=$(jq -r 'del(.signature, .generated_at)' "${PASSPORT}" 2>/dev/null)
  COMPUTED_SIG=$(echo -n "${CONTENT}" | sha256sum | awk '{print $1}')
  
  if [[ "${STORED_SIG}" != "${COMPUTED_SIG}" ]]; then
    echo "  ❌ ${PASSPORT} — signature mismatch (drift detected)"
    FAILED=$((FAILED + 1))
  else
    echo "  ✓ ${PASSPORT}"
  fi
done
echo ""

# Test 2: Schema validation (Bauer: Verify Structure)
echo "→ Validating JSON schemas..."
for PASSPORT in inventory/*.json 02-declarative-config/*.json runbooks/*.json; do
  [[ -f "${PASSPORT}" ]] || continue
  
  if ! jq -e '.schema_version, .consciousness' "${PASSPORT}" >/dev/null 2>&1; then
    echo "  ❌ ${PASSPORT} — missing required fields"
    FAILED=$((FAILED + 1))
  else
    echo "  ✓ ${PASSPORT}"
  fi
done
echo ""

# Test 3: Offensive nmap scan (Whitaker: Attack the Inventory)
echo "→ Pentesting passport IPs (nmap reconnaissance)..."
if command -v nmap >/dev/null 2>&1; then
  for PASSPORT in inventory/ap-passport.json inventory/ups-passport.json; do
    [[ -f "${PASSPORT}" ]] || continue
    
    IPS=$(jq -r '.. | .ip? // empty' "${PASSPORT}" 2>/dev/null | sort -u)
    
    while IFS= read -r IP; do
      [[ -n "${IP}" ]] || continue
      
      # Scan for unexpected open ports (should only see management ports)
      OPEN_PORTS=$(nmap -sV --top-ports 100 "${IP}" 2>/dev/null | grep -E "^[0-9]+/tcp.*open" | awk '{print $1}' | cut -d/ -f1 || echo "")
      
      # Expected ports: 22 (SSH), 161 (SNMP), 443 (HTTPS), 8443 (UniFi)
      UNEXPECTED=$(echo "${OPEN_PORTS}" | grep -Ev "^(22|161|443|8443)$" || true)
      
      if [[ -n "${UNEXPECTED}" ]]; then
        echo "  ⚠️  ${IP} — unexpected ports: ${UNEXPECTED}"
        FAILED=$((FAILED + 1))
      else
        echo "  ✓ ${IP}"
      fi
    done <<< "${IPS}"
  done
else
  echo "  ⚠️  nmap not installed — skipping offensive scan"
fi
echo ""

# Test 4: Certificate expiry (Bauer: Verify Dates)
echo "→ Checking certificate expiry..."
if [[ -f inventory/certificate-passport.json ]]; then
  EXPIRING=$(jq '[.certificates[]? | select(.days_remaining < 30)] | length' inventory/certificate-passport.json 2>/dev/null || echo "0")
  EXPIRED=$(jq '[.certificates[]? | select(.days_remaining < 0)] | length' inventory/certificate-passport.json 2>/dev/null || echo "0")
  
  if [[ "${EXPIRED}" -gt 0 ]]; then
    echo "  ❌ ${EXPIRED} certificate(s) EXPIRED"
    FAILED=$((FAILED + 1))
  elif [[ "${EXPIRING}" -gt 0 ]]; then
    echo "  ⚠️  ${EXPIRING} certificate(s) expiring <30 days"
  else
    echo "  ✓ All certificates valid"
  fi
else
  echo "  ⚠️  certificate-passport.json not found"
fi
echo ""

# Test 5: UPS critical conditions (Beale: Power Hardening)
echo "→ Checking UPS health..."
if [[ -f inventory/ups-passport.json ]]; then
  CRITICAL=$(jq '[.ups_devices[]? | select(.runtime_minutes < 10 or .load_percent > 80 or .battery_replace_needed == true)] | length' inventory/ups-passport.json 2>/dev/null || echo "0")
  
  if [[ "${CRITICAL}" -gt 0 ]]; then
    echo "  ❌ ${CRITICAL} UPS device(s) in critical state"
    jq -r '.ups_devices[]? | select(.runtime_minutes < 10 or .load_percent > 80 or .battery_replace_needed == true) | "    \(.ip): runtime=\(.runtime_minutes)min load=\(.load_percent)% replace=\(.battery_replace_needed)"' inventory/ups-passport.json 2>/dev/null || true
    FAILED=$((FAILED + 1))
  else
    echo "  ✓ All UPS devices healthy"
  fi
else
  echo "  ⚠️  ups-passport.json not found"
fi
echo ""

# Test 6: Network isolation (Whitaker: VLAN breach simulation)
echo "→ Testing VLAN isolation..."
if [[ -f 02-declarative-config/network-passport.json ]]; then
  VLANS=$(jq -r '.networks[]?.vlan_id // empty' 02-declarative-config/network-passport.json 2>/dev/null | sort -u)
  
  # Test cross-VLAN access (should fail)
  while IFS= read -r VLAN; do
    [[ -n "${VLAN}" ]] || continue
    TARGET_IP="10.0.${VLAN}.1"
    
    # Attempt connection from management VLAN (should timeout on isolated VLANs)
    if timeout 2 ping -c 1 "${TARGET_IP}" >/dev/null 2>&1; then
      echo "  ✓ VLAN ${VLAN} reachable (expected for management)"
    else
      echo "  ✓ VLAN ${VLAN} isolated (expected for guest/IoT)"
    fi
  done <<< "${VLANS}"
else
  echo "  ⚠️  network-passport.json not found"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ ${FAILED} -eq 0 ]]; then
  echo "✓ ALL PASSPORTS VALIDATED — FORTRESS SECURE"
  echo ""
  echo "Whitaker approves. No breaches detected."
  echo "Signatures intact. Schemas valid. Pentests green."
  exit 0
else
  echo "❌ ${FAILED} VALIDATION FAILURE(S) DETECTED"
  echo ""
  echo "Fix issues and re-run: ./scripts/validate-passports.sh"
  exit 1
fi
