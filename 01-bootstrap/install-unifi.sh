#!/bin/bash
#
# UniFi Network Controller Bootstrap Script (Linux/macOS)
# Installs UniFi Network Controller 8.5.93+ with dependencies
#
# Usage:
#   bash install-unifi.sh [controller_ip]
#
# Example:
#   bash install-unifi.sh 10.0.1.1

set -euo pipefail

CONTROLLER_IP="${1:-10.0.1.1}"
REQUIRED_UNIFI_VERSION="8.5.93"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 UniFi Network Controller Bootstrap (Linux)${NC}"
echo -e "${YELLOW}Target IP: $CONTROLLER_IP${NC}"

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}Cannot detect Linux distribution${NC}"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    DISTRO="macos"
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS ($DISTRO)${NC}"

# Check root/sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root or with sudo${NC}"
   exit 1
fi

# Step 1: Install Java 17
echo -e "\n${GREEN}📦 Step 1: Installing Java 17 (OpenJDK)${NC}"

if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
    apt-get update -qq
    apt-get install -y openjdk-17-jre-headless ca-certificates apt-transport-https wget gnupg
elif [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]] || [[ "$DISTRO" == "fedora" ]]; then
    yum install -y java-17-openjdk-headless wget
elif [[ "$DISTRO" == "macos" ]]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install openjdk@17
else
    echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
    exit 1
fi

# Verify Java
JAVA_VERSION=$(java -version 2>&1 | grep version | awk -F '"' '{print $2}' | cut -d'.' -f1)
if [[ "$JAVA_VERSION" != "17" ]]; then
    echo -e "${RED}Java 17 installation failed. Found version: $JAVA_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Java 17 installed${NC}"

# Step 2: Install MongoDB 7.0
echo -e "\n${GREEN}📦 Step 2: Installing MongoDB 7.0${NC}"

if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
    
    if [[ "$DISTRO" == "ubuntu" ]]; then
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    else
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    fi
    
    apt-get update -qq
    apt-get install -y mongodb-org
    systemctl enable mongod
    systemctl start mongod
    
elif [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]] || [[ "$DISTRO" == "fedora" ]]; then
    cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
    
    yum install -y mongodb-org
    systemctl enable mongod
    systemctl start mongod
    
elif [[ "$DISTRO" == "macos" ]]; then
    brew tap mongodb/brew
    brew install mongodb-community@7.0
    brew services start mongodb-community@7.0
fi

echo -e "${GREEN}✅ MongoDB 7.0 installed and running${NC}"

# Step 3: Install UniFi Network Controller
echo -e "\n${GREEN}📦 Step 3: Installing UniFi Network Controller ${REQUIRED_UNIFI_VERSION}${NC}"

if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
    # Add UniFi repository
    echo "deb [ arch=amd64,arm64 ] https://www.ui.com/downloads/unifi/debian stable ubiquiti" | tee /etc/apt/sources.list.d/100-ubnt-unifi.list
    wget -qO - https://dl.ui.com/unifi/unifi-repo.gpg | apt-key add -
    
    apt-get update -qq
    apt-get install -y unifi
    
elif [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]] || [[ "$DISTRO" == "fedora" ]]; then
    cat > /etc/yum.repos.d/unifi.repo <<EOF
[unifi]
name=UniFi Repository
baseurl=https://www.ui.com/downloads/unifi/rpm/stable/
enabled=1
gpgcheck=1
gpgkey=https://dl.ui.com/unifi/unifi-repo.gpg
EOF
    
    yum install -y unifi
    
elif [[ "$DISTRO" == "macos" ]]; then
    UNIFI_URL="https://dl.ui.com/unifi/${REQUIRED_UNIFI_VERSION}/UniFi.pkg"
    UNIFI_PKG="/tmp/UniFi.pkg"
    
    echo -e "${YELLOW}Downloading UniFi from $UNIFI_URL...${NC}"
    curl -L -o "$UNIFI_PKG" "$UNIFI_URL"
    
    echo -e "${YELLOW}Installing UniFi...${NC}"
    installer -pkg "$UNIFI_PKG" -target /
    
    rm -f "$UNIFI_PKG"
fi

# Start UniFi service
if [[ "$OS" == "linux" ]]; then
    systemctl enable unifi
    systemctl start unifi
    echo -e "${GREEN}✅ UniFi service started${NC}"
elif [[ "$OS" == "macos" ]]; then
    launchctl load /Library/LaunchDaemons/com.ubnt.UniFi.plist 2>/dev/null || true
    echo -e "${GREEN}✅ UniFi service started${NC}"
fi

# Step 4: Configure Firewall (Linux only)
if [[ "$OS" == "linux" ]]; then
    echo -e "\n${GREEN}📦 Step 4: Configuring Firewall${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw allow 8443/tcp comment "UniFi Web UI"
        ufw allow 3478/udp comment "UniFi STUN"
        ufw allow 10001/udp comment "UniFi Discovery"
        ufw allow 8080/tcp comment "UniFi Device Comm"
        echo -e "${GREEN}✅ UFW firewall rules configured${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=8443/tcp  # Web UI
        firewall-cmd --permanent --add-port=3478/udp  # STUN
        firewall-cmd --permanent --add-port=10001/udp # Discovery
        firewall-cmd --permanent --add-port=8080/tcp  # Device Comm
        firewall-cmd --reload
        echo -e "${GREEN}✅ firewalld rules configured${NC}"
    else
        echo -e "${YELLOW}⚠️  No firewall detected. Ensure ports 8443, 3478, 10001, 8080 are accessible${NC}"
    fi
fi

# Wait for UniFi to start
echo -e "\n${YELLOW}Waiting for UniFi controller to start (30 seconds)...${NC}"
sleep 30

# Final instructions
echo -e "\n${GREEN}✅ Installation Complete!${NC}"
echo -e "\n${CYAN}UniFi Network Controller is now running at:${NC}"
echo -e "  ${NC}https://$CONTROLLER_IP:8443${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  ${NC}1. Open browser and navigate to controller URL${NC}"
echo -e "  ${NC}2. Complete initial setup wizard${NC}"
echo -e "  ${NC}3. Create local admin account (no 2FA)${NC}"
echo -e "  ${NC}4. Run adopt-devices.py to auto-adopt USG and switches${NC}"
echo -e "\n${YELLOW}⚠️  Remember to update shared/inventory.yaml with admin credentials${NC}"

echo -e "\n${GREEN}🎉 Bootstrap complete! Controller URL: https://$CONTROLLER_IP:8443${NC}"
