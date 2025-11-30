#!/bin/bash
set -euo pipefail
# Rylan v5.0 UniFi Controller Bootstrap
# Target: Ubuntu 24.04 LTS | MongoDB 7.0 | UniFi Network 8.5.93
# Binds to 0.0.0.0 for management VLAN access
echo "=== Rylan v5.0 UniFi Controller Installation ==="
echo "Target: 10.0.1.20 (Management VLAN)"
echo ""
# Verify Ubuntu 24.04
if ! grep -q "24.04" /etc/os-release; then
    echo "ERROR: Requires Ubuntu 24.04 LTS"
    exit 1
fi
# Update system
echo "[1/6] Updating system packages..."
apt-get update && apt-get upgrade -y
# Install dependencies
echo "[2/6] Installing dependencies..."
apt-get install -y ca-certificates apt-transport-https gnupg curl
# Add MongoDB 7.0 repository
echo "[3/6] Adding MongoDB 7.0 repository..."
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list
# Install MongoDB
echo "[4/6] Installing MongoDB 7.0..."
apt-get update
apt-get install -y mongodb-org
systemctl enable mongod
systemctl start mongod
# Verify MongoDB
if ! systemctl is-active --quiet mongod; then
    echo "ERROR: MongoDB failed to start"
    exit 1
fi
# Add UniFi repository
echo "[5/6] Adding UniFi Network repository..."
curl -fsSL https://dl.ui.com/unifi/unifi-repo.gpg | \
    gpg --dearmor -o /usr/share/keyrings/ubiquiti-archive-keyring.gpg
echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/ubiquiti-archive-keyring.gpg ] \
https://www.ui.com/downloads/unifi/debian stable ubiquiti" | \
    tee /etc/apt/sources.list.d/100-ubiquiti-unifi.list
# Install UniFi Controller 8.5.93
echo "[6/6] Installing UniFi Network 8.5.93..."
apt-get update
apt-get install -y unifi=8.5.93-27487-1
# Hold package version (prevent auto-upgrades)
apt-mark hold unifi
# Configure binding to 0.0.0.0
echo "Configuring controller to bind 0.0.0.0..."
mkdir -p /usr/lib/unifi/data
cat > /usr/lib/unifi/data/system.properties <<EOF
# Rylan v5.0 - Bind to all interfaces for VLAN 1 access
system_ip=0.0.0.0
EOF
# Restart UniFi service
systemctl restart unifi
# Wait for controller to start
echo "Waiting for controller to initialize..."
sleep 30
# Verify service
if ! systemctl is-active --quiet unifi; then
    echo "ERROR: UniFi controller failed to start"
    exit 1
fi
# Get controller URL
CONTROLLER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "UniFi Controller Installation Complete"
echo ""
echo "Controller URL: https://${CONTROLLER_IP}:8443"
echo "Expected IP: https://10.0.1.20:8443"
echo ""
echo "Next Steps:"
echo " 1. Access controller web UI"
echo " 2. Complete initial setup wizard"
echo " 3. Create admin credentials"
echo " 4. Add credentials to 02-declarative-config/inventory.yaml"
echo " 5. Run: bash scripts/ignite.sh"
echo ""
echo "MongoDB: $(mongod --version | head -n1)"
echo "UniFi: $(dpkg -l | grep unifi | awk '{print $3}')"
