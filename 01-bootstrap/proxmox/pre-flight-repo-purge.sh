#!/usr/bin/env bash
# pre-flight-repo-purge.sh — Eternal Proxmox Repo Purge (T3-ETERNAL v6)
# Purpose: Remove enterprise repos, configure community no-subscription
# Usage: sudo ./pre-flight-repo-purge.sh
# Idempotent: Safe to run multiple times

set -euo pipefail

# Constants
readonly LOG_FILE="/tmp/repo-purge.log"
readonly ENTERPRISE_REPOS=(
	"/etc/apt/sources.list.d/pve-enterprise.list"
	"/etc/apt/sources.list.d/ceph-squid.list"
)
readonly COMMUNITY_REPO="/etc/apt/sources.list.d/pve-no-subscription.list"

# Detect Debian release
DEBIAN_RELEASE=$(lsb_release -cs 2>/dev/null || echo "unknown")

# Root check
if [[ $EUID -ne 0 ]]; then
	echo "❌ Must run as root"
	exit 1
fi

# Version-specific handling
case "$DEBIAN_RELEASE" in
	trixie)
		COMMUNITY_URL="deb http://download.proxmox.com/debian/pve trixie pve-no-subscription"
		;;
	bookworm)
		COMMUNITY_URL="deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription"
		;;
	*)
		echo "⚠️  Unknown Debian release: $DEBIAN_RELEASE — Skipping purge"
		exit 0
		;;
esac

echo "🔥 Purging enterprise repos ($DEBIAN_RELEASE)..." | tee "$LOG_FILE"

# Remove enterprise repos
for repo in "${ENTERPRISE_REPOS[@]}"; do
	[[ -f "$repo" ]] && rm -f "$repo"
done

# Add community repo (idempotent)
if [[ -f "$COMMUNITY_REPO" ]] && grep -q "pve-no-subscription" "$COMMUNITY_REPO"; then
	echo "✅ Community repo already configured"
else
	echo "$COMMUNITY_URL" > "$COMMUNITY_REPO"
fi

# Refresh apt
apt update --allow-insecure-repositories >> "$LOG_FILE" 2>&1

# Verify
if apt update 2>&1 | grep -q "enterprise.proxmox.com"; then
	echo "❌ Enterprise repos still present"
	exit 1
fi

echo "✅ Purge complete — Clean $DEBIAN_RELEASE stream"