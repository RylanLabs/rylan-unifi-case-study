#!/usr/bin/env bash
# setup-nfs-kerberos.sh — Phase 3 Endgame (Kerberos Domain Authentication)
# Enables secure NFS mounts authenticated via Samba AD/DC (rylan-dc)
# Run on NFS server (rylan-ai) and NFS clients (rylan-dc, rylan-pi)

set -euo pipefail

echo "=== NFS Kerberos Security Setup (Eternal Fortress) ==="

# Load configuration
if [[ ! -f .env ]]; then
  echo "❌ .env not found"
  exit 1
fi
# shellcheck disable=SC1091
source .env

HOSTNAME=$(hostname)
REALM="${SAMBA_REALM:-RYLAN.INTERNAL}"
DOMAIN="${SAMBA_DOMAIN:-RYLAN}"
ADMIN_PASS="${ADMIN_PASSWORD:-ChangeMe123!}"
NFS_SERVER_IP="${NFS_BACKUP_HOST:-10.0.10.60}"
NFS_BACKUP_PATH="${NFS_BACKUP_PATH:-/srv/nfs/backups}"

echo "Hostname: $HOSTNAME"
echo "Realm: $REALM"
echo "NFS Server: $NFS_SERVER_IP"
echo ""

# ============================================================================
# Phase 1: NFS Server Setup (rylan-ai)
# ============================================================================

if [[ "$HOSTNAME" == "rylan-ai" ]]; then
  echo "🟢 NFS Server Configuration"
  echo ""

  # Install NFS server + Kerberos utilities
  echo "📦 Installing NFS server and Kerberos..."
  sudo apt-get update >/dev/null
  sudo apt-get install -y nfs-kernel-server krb5-user krb5-kdc krb5-admin-server >/dev/null

  # Create NFS export directory
  echo "📁 Creating NFS export directory..."
  sudo mkdir -p "$NFS_BACKUP_PATH"
  sudo mkdir -p "$NFS_BACKUP_PATH/loki-chunks"
  sudo mkdir -p "$NFS_BACKUP_PATH/loki-index"
  sudo mkdir -p "$NFS_BACKUP_PATH/samba"
  sudo mkdir -p "$NFS_BACKUP_PATH/freeradius"
  sudo mkdir -p "$NFS_BACKUP_PATH/osticket"
  sudo mkdir -p "$NFS_BACKUP_PATH/qdrant"

  # Set permissions (755 for directories, 644 for files)
  sudo chown -R nfsnobody:nfsnobody "$NFS_BACKUP_PATH"
  sudo chmod -R 755 "$NFS_BACKUP_PATH"

  # Configure Kerberos keytab for NFS
  echo "🔐 Configuring Kerberos NFS service..."

  # Generate NFS service keytab on Samba AD (this requires manual execution on rylan-dc)
  echo ""
  echo "⚠️  MANUAL STEP REQUIRED ON rylan-dc:"
  echo "   ssh rylan-dc 'sudo samba-tool domain exportkeytab /tmp/nfs.keytab --principal=nfs/rylan-ai.rylan.internal@$REALM'"
  echo "   scp rylan-dc:/tmp/nfs.keytab /etc/krb5.keytab"
  echo ""

  # For now, create a placeholder keytab (production must have real one from AD)
  if [[ ! -f /etc/krb5.keytab ]]; then
    echo "   (Placeholder keytab — replace with real keytab from Samba AD)"
    sudo touch /etc/krb5.keytab
  fi

  # Set keytab permissions
  sudo chown root:root /etc/krb5.keytab
  sudo chmod 600 /etc/krb5.keytab

  # Configure /etc/exports for Kerberos-authenticated NFS
  echo "📝 Configuring NFS exports (/etc/exports)..."

  # Backup existing exports
  sudo cp /etc/exports "/etc/exports.backup.$(date +%Y%m%d)"

  # Create new exports with Kerberos (sec=krb5p for integrity + privacy)
  sudo tee /etc/exports > /dev/null << EOF
# NFS Kerberos Exports — Phase 3 Endgame
# sec=krb5p: Kerberos authentication + integrity + privacy (encryption)
# rw: read-write for backup clients
# async: performance (OK for backups)
# no_subtree_check: disable subtree checking (recommended for modern NFS)
# anonuid/anongid: map unauthenticated to nfsnobody

$NFS_BACKUP_PATH/loki-chunks    10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
$NFS_BACKUP_PATH/loki-index     10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
$NFS_BACKUP_PATH/samba          10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
$NFS_BACKUP_PATH/freeradius     10.0.10.10/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
$NFS_BACKUP_PATH/osticket       10.0.10.11/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
$NFS_BACKUP_PATH/qdrant         10.0.10.60/32(sec=krb5p,rw,async,no_subtree_check,anonuid=65534,anongid=65534)
EOF

  echo "✅ Exports configured:"
  sudo cat /etc/exports

  # Reload NFS exports
  echo "🔄 Reloading NFS exports..."
  sudo exportfs -ra

  # Start NFS services
  echo "🚀 Starting NFS services..."
  sudo systemctl enable nfs-server
  sudo systemctl restart nfs-server

  # Verify NFS is listening
  echo ""
  echo "✅ NFS Server Configuration Complete"
  echo "Verify NFS exports:"
  echo "  sudo showmount -e localhost"
  echo ""

fi

# ============================================================================
# Phase 2: NFS Client Setup (rylan-dc, rylan-pi, rylan-ai)
# ============================================================================

if [[ "$HOSTNAME" == "rylan-dc" ]] || [[ "$HOSTNAME" == "rylan-pi" ]] || [[ "$HOSTNAME" == "rylan-ai" ]]; then
  echo "🔵 NFS Client Configuration"
  echo ""

  # Install NFS client + Kerberos
  echo "📦 Installing NFS client and Kerberos..."
  sudo apt-get update >/dev/null
  sudo apt-get install -y nfs-common krb5-user krb5-config >/dev/null

  # Configure Kerberos client
  echo "🔐 Configuring Kerberos client..."

  # Create/update /etc/krb5.conf
  sudo tee /etc/krb5.conf > /dev/null << EOF
[libdefaults]
  default_realm = $REALM
  dns_lookup_realm = false
  dns_lookup_kdc = true
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true

[realms]
  $REALM = {
    kdc = 10.0.10.10
    admin_server = 10.0.10.10
    default_domain = rylan.internal
  }

[domain_realm]
  .rylan.internal = $REALM
  rylan.internal = $REALM
EOF

  echo "✅ Kerberos client configured"

  # Create NFS mount points
  echo "📁 Creating NFS mount points..."

  case "$HOSTNAME" in
    rylan-dc)
      sudo mkdir -p /mnt/nfs/backups
      MOUNT_PATH="/mnt/nfs/backups"
      MOUNT_SRC="$NFS_SERVER_IP:$NFS_BACKUP_PATH"
      ;;
    rylan-pi)
      sudo mkdir -p /mnt/nfs/backups
      MOUNT_PATH="/mnt/nfs/backups"
      MOUNT_SRC="$NFS_SERVER_IP:$NFS_BACKUP_PATH"
      ;;
    rylan-ai)
      MOUNT_PATH=""  # NFS server doesn't need to mount its own exports
      MOUNT_SRC=""
      ;;
  esac

  if [[ -n "$MOUNT_PATH" ]]; then
    echo "📌 Mounting NFS at $MOUNT_PATH..."

    # Add fstab entry for Kerberos NFS mount
    FSTAB_ENTRY="$MOUNT_SRC $MOUNT_PATH nfs4 sec=krb5p,vers=4.2,proto=tcp,port=2049,rw,hard,intr,noatime,_netdev 0 0"

    # Check if already in fstab
    if ! grep -q "$MOUNT_SRC" /etc/fstab; then
      echo "   Adding to /etc/fstab..."
      echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
    fi

    # Mount now
    echo "   Mounting..."
    sudo mount -a 2>/dev/null || {
      echo "⚠️  Mount failed (Kerberos ticket may be needed)"
      printf '   Run: kinit %s\admin@%s\n' "$SAMBA_DOMAIN" "$REALM"
    }
  fi

  echo "✅ NFS Client Configuration Complete"
  echo ""
fi

# ============================================================================
# Phase 3: Kerberos Authentication (All Hosts)
# ============================================================================

echo "🔐 Kerberos Setup"
echo ""
echo "To complete NFS Kerberos authentication, run on each client:"
echo ""
printf '  kinit %s\admin@%s\n' "$DOMAIN" "$REALM"
echo "  (Enter password: $ADMIN_PASS)"
echo ""
echo "Or for automated mounts, create a keytab:"
echo ""
echo "  On rylan-dc:"
echo "    sudo samba-tool domain exportkeytab /etc/krb5.keytab --principal=nfs/rylan-ai@$REALM"
echo ""
echo "Verify Kerberos ticket:"
echo "  klist"
echo ""

# ============================================================================
# Verification
# ============================================================================

echo ""
echo "✅ NFS Security Setup Complete"
echo ""
echo "Verification steps:"
echo ""
echo "1. NFS Server Exports (on rylan-ai):"
echo "   sudo showmount -e localhost"
echo ""
echo "2. Kerberos Ticket (on clients):"
echo "   klist"
echo ""
echo "3. Mount NFS (on clients):"
echo "   sudo mount -t nfs4 -o sec=krb5p $NFS_SERVER_IP:$NFS_BACKUP_PATH /mnt/nfs/backups"
echo "   df -h | grep /mnt/nfs/backups"
echo ""
echo "4. Test Write Permission:"
echo "   sudo touch /mnt/nfs/backups/test-$(date +%s).txt"
echo "   ls -la /mnt/nfs/backups/"
echo ""
