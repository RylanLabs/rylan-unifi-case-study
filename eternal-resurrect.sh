#!/usr/bin/env bash
# Eternal Resurrect — One-Command Fortress Deployment
# git clone && ./eternal-resurrect.sh

set -euo pipefail

echo "=== Eternal Resurrection Initiated ==="

# Prerequisites check
command -v python3 >/dev/null || { echo "❌ python3 required"; exit 1; }
command -v git >/dev/null || { echo "❌ git required"; exit 1; }

# Install Python dependencies
echo "📦 Installing Python dependencies..."
python3 -m pip install --quiet --upgrade pip
python3 -m pip install --quiet -r requirements.txt

# Run guardian audit
echo "🛡️  Running guardian audit..."
python3 guardian/audit-eternal.py

# Validate policy table
echo "📋 Validating policy table..."
python3 -c "import yaml; data=yaml.safe_load(open('02-declarative-config/policy-table.yaml')); assert len(data['rules']) == 10, 'Rule count mismatch'"

# Run tests
echo "🧪 Running test suite..."
python3 -m pytest -q

echo ""
echo "✅ Eternal fortress resurrected successfully"
echo "   Policy table: 10 rules (Phase 2 locked)"
echo "   Guardian audit: passed"
echo "   Tests: all green"
echo ""
echo "Next steps:"
echo "  1. Deploy FreeRADIUS: cd 01-bootstrap/freeradius && docker-compose up -d"
echo "  2. Apply policy table: cd 02-declarative-config && python apply.py"
echo "  3. Configure cron: sudo cp 01-bootstrap/backup-orchestrator.sh /opt/rylan/ && (crontab -l; echo '0 2 * * * /opt/rylan/backup-orchestrator.sh') | crontab -"
echo ""
echo "The fortress is operational. The ride continues."
