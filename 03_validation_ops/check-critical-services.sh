#!/usr/bin/env bash
set -euo pipefail

echo "=== Critical Service Health Check ==="

# osTicket API
echo -n "osTicket (10.0.30.40)... "
if curl -sf -H "X-API-Key: ${OSTICKET_KEY:-demo}" https://10.0.30.40/api/tickets >/dev/null 2>&1; then
  echo "✓ Responsive"
else
  echo "✗ Unreachable"
fi

# AI Triage Engine
echo -n "AI Triage (10.0.10.60:8000)... "
if curl -sf http://10.0.10.60:8000/health >/dev/null 2>&1; then
  echo "✓ Healthy"
else
  echo "✗ Down"
fi

# FreePBX SIP (if asterisk installed)
if command -v asterisk >/dev/null 2>&1; then
  echo -n "FreePBX SIP peers... "
  PEERS=$(asterisk -rx "sip show peers" | grep -c "10.0.40" || true)
  echo "$PEERS registered"
else
  echo "⚠️  Asterisk not installed (skip SIP check)"
fi

echo "✅ Health check complete"
