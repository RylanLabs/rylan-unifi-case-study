#!/bin/bash
set -euo pipefail
# Script: scripts/test-api-paths.sh
# Purpose: Header hygiene inserted
# Guardian: gatekeeper
# Date: 2025-12-13T01:30:33-06:00
# Consciousness: 4.6

UNIFI_IP="192.168.1.13"
UNIFI_USER="admin"
UNIFI_PASS='M3@h)m3.w1f1'

COOKIES="/tmp/test-cookies.txt"

echo "Testing authentication..."
curl -sk -c "$COOKIES" \
  -X POST "https://${UNIFI_IP}/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$UNIFI_USER\",\"password\":\"$UNIFI_PASS\"}" \
  >/tmp/auth-response.json

echo "Auth response:"
jq '.' </tmp/auth-response.json

echo ""
echo "Testing different API paths..."

# Test path 1: v2 API
echo "1. Testing /proxy/network/v2/api/site/default/stat/device"
curl -sk -b "$COOKIES" \
  "https://${UNIFI_IP}/proxy/network/v2/api/site/default/stat/device" \
  >/tmp/test1.json
echo "Response size: $(wc -c </tmp/test1.json) bytes"
head -c 200 /tmp/test1.json
echo ""

# Test path 2: v1 API
echo "2. Testing /proxy/network/api/s/default/stat/device"
curl -sk -b "$COOKIES" \
  "https://${UNIFI_IP}/proxy/network/api/s/default/stat/device" \
  >/tmp/test2.json
echo "Response size: $(wc -c </tmp/test2.json) bytes"
head -c 200 /tmp/test2.json
echo ""

# Test path 3: Direct API
echo "3. Testing /api/s/default/stat/device"
curl -sk -b "$COOKIES" \
  "https://${UNIFI_IP}/api/s/default/stat/device" \
  >/tmp/test3.json
echo "Response size: $(wc -c </tmp/test3.json) bytes"
head -c 200 /tmp/test3.json
echo ""

echo "Which path returned valid JSON?"
for i in 1 2 3; do
  if jq empty /tmp/test$i.json 2>/dev/null; then
    echo "  ✅ Path $i is valid"
  else
    echo "  ❌ Path $i failed"
  fi
done

rm -f /tmp/test*.json /tmp/auth-response.json "$COOKIES"
