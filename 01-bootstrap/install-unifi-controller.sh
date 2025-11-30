#!/usr/bin/env bash
# install-unifi-controller.sh
# Provision UniFi Network Application 8.5.93 on Ubuntu 24.04 (Jammy)
# Includes: OpenJDK 17, MongoDB 7.0, UniFi bound to 0.0.0.0
# Idempotent: Safe to re-run; skips already installed components.

set -euo pipefail
IFS=$'\n\t'

UNI_VERSION="8.5.93"
MONGO_VERSION="7.0"
UNIFI_SERVICE="unifi"
SITE_IP="${1:-0.0.0.0}"  # Bind interface (0.0.0.0 for all)

log() { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

if [[ $EUID -ne 0 ]]; then
  err "Run as root or with sudo"; exit 1
fi

log "Updating APT index"
apt-get update -qq

log "Installing dependencies (curl, gnupg, ca-certificates)"
apt-get install -y curl gnupg ca-certificates apt-transport-https jq

if ! java -version 2>&1 | grep -q "17"; then
  log "Installing OpenJDK 17"
  apt-get install -y openjdk-17-jre-headless
else
  warn "OpenJDK 17 already present; skipping"
fi

if ! systemctl status mongod >/dev/null 2>&1; then
  log "Adding MongoDB $MONGO_VERSION repository"
  curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/${MONGO_VERSION} multiverse" > /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list
  apt-get update -qq
  log "Installing MongoDB"
  apt-get install -y mongodb-org
  systemctl enable mongod
  systemctl start mongod
else
  warn "MongoDB already running; skipping"
fi

if ! dpkg -l | grep -q unifi; then
  log "Adding UniFi repository"
  curl -fsSL https://dl.ui.com/unifi/unifi-repo.gpg | gpg --dearmor -o /usr/share/keyrings/unifi-repo.gpg
  echo "deb [signed-by=/usr/share/keyrings/unifi-repo.gpg] https://www.ui.com/downloads/unifi/debian stable ubiquiti" > /etc/apt/sources.list.d/100-ubnt-unifi.list
  apt-get update -qq
  log "Installing UniFi Network Application ${UNI_VERSION}"
  apt-get install -y unifi
else
  warn "UniFi already installed; ensuring latest stable"
  apt-get install -y unifi
fi

log "Configuring bind address to ${SITE_IP} (reverse proxy optional)"
# UniFi Java opts in /usr/lib/unifi/data/system.properties
PROP_FILE="/usr/lib/unifi/data/system.properties"
mkdir -p /usr/lib/unifi/data
if grep -q "unifi.http.addr" "$PROP_FILE" 2>/dev/null; then
  sed -i "s/^unifi.http.addr=.*/unifi.http.addr=${SITE_IP}/" "$PROP_FILE"
else
  echo "unifi.http.addr=${SITE_IP}" >> "$PROP_FILE"
fi
if grep -q "unifi.https.addr" "$PROP_FILE" 2>/dev/null; then
  sed -i "s/^unifi.https.addr=.*/unifi.https.addr=${SITE_IP}/" "$PROP_FILE"
else
  echo "unifi.https.addr=${SITE_IP}" >> "$PROP_FILE"
fi

log "Restarting UniFi service"
systemctl restart ${UNIFI_SERVICE}
systemctl enable ${UNIFI_SERVICE}

log "Waiting for controller (8443)"
for i in {1..30}; do
  if curl -ks https://localhost:8443/ | grep -q "UniFi"; then
    log "Controller responding on 8443"
    break
  fi
  sleep 2
done

log "Summary"
log "Java Version: $(java -version 2>&1 | head -n1)"
log "MongoDB: $(mongod --version | head -n1)"
log "UniFi Service: $(systemctl is-active ${UNIFI_SERVICE})"
log "Bind Address: ${SITE_IP}" 
log "Next: Access https://<host>:8443 and complete setup wizard (disable 2FA for automation flow)"
