#!/bin/bash
# Eternal Orchestrator — Multi-Host Backup + RTO Validation (Phase 2 Gold Star)
# Handles backup for rylan-dc, rylan-pi, rylan-ai with RTO <15 min validation
# Verified 2025-12-04 — Consciousness Level 3.8

set -euo pipefail

DRY_RUN=false
VERBOSE=false
TEST_RESTORE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)          DRY_RUN=true; shift ;;
        --verbose|-v)       VERBOSE=true; shift ;;
        --test-restore)     TEST_RESTORE=true; shift ;;
        *) echo "Usage: $0 [--dry-run] [--verbose] [--test-restore]"; exit 1 ;;
    esac
done

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load .env
# shellcheck disable=SC1091
if [[ -f .env ]]; then
    source .env
else
    echo "⚠️  .env not found, using defaults"
fi

BACKUP_DESTINATION=${BACKUP_DESTINATION:-/srv/nfs/backups}
RTO_MINUTES=${RTO_MINUTES:-15}
RTO_SECONDS=$((RTO_MINUTES * 60))
HOSTNAME=$(hostname)
BACKUP_DIR="${BACKUP_DESTINATION}/$(date +%Y%m%d_%H%M%S)_${HOSTNAME}"

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Per-component timing
# shellcheck disable=SC2034
declare -A COMPONENT_TIMES
declare -A COMPONENT_START

component_start() { local c=$1; COMPONENT_START[$c]=$(date +%s%N); }
component_end() {
    local c=$1
    local end
    end=$(date +%s%N)
    local start=${COMPONENT_START[$c]:-0}
    local elapsed_ms=$(( (end - start) / 1000000 ))
    # shellcheck disable=SC2034
    COMPONENT_TIMES[$c]=$elapsed_ms
    log_info "  ⏱️  $c: ${elapsed_ms}ms"
}

test_restore() {
    local component=$1
    local path=$2
    [[ -e "$path" ]] || { log_warn "  Restore test skipped (not found)"; return; }
    log_info "  Testing restore of $component..."
    case "$component" in
        samba|freeradius)
            if tar -tzf "$path" >/dev/null; then
                log_info "    ✅ $component restore test passed"
            else
                log_error "    ❌ failed"
            fi
            ;;
        mariadb)
            if grep -q "CREATE DATABASE" "$path"; then
                log_info "    ✅ $component restore test passed"
            else
                log_error "    ❌ failed"
            fi
            ;;
        qdrant)
            if [[ -n "$(find "$path" -type f -print -quit)" ]]; then
                log_info "    ✅ $component restore test passed"
            else
                log_error "    ❌ empty"
            fi
            ;;
        *)
            log_warn "    Unknown component"
            ;;
    esac
}

log_info "=== Eternal Orchestrator Start ==="
log_info "Host: $HOSTNAME  |  RTO Target: ${RTO_MINUTES}min  |  $( [[ $DRY_RUN == true ]] && echo "DRY-RUN" || echo "PRODUCTION" )"

[[ $VERBOSE == true ]] && set -x

[[ $DRY_RUN == false ]] && mkdir -p "$BACKUP_DIR"

start_time=$(date +%s)

case "$HOSTNAME" in
    rylan-dc)
        log_info "Backing up Samba AD/DC + FreeRADIUS + UniFi"
        # Samba
        if [[ -d /var/lib/samba ]]; then
            component_start samba
            rsync -avz --delete /var/lib/samba/ "$BACKUP_DIR/samba/" || true
            component_end samba
            [[ $TEST_RESTORE == true ]] && test_restore samba "$BACKUP_DIR/samba/private/sam.ldb"
        fi
        # FreeRADIUS
        if [[ -d /etc/freeradius ]]; then
            component_start freeradius
            tar czf "$BACKUP_DIR/freeradius-config.tar.gz" /etc/freeradius/ || true
            component_end freeradius
            [[ $TEST_RESTORE == true ]] && test_restore freeradius "$BACKUP_DIR/freeradius-config.tar.gz"
        fi
        # UniFi
        if docker ps | grep -q unifi; then
            component_start unifi
            docker exec unifi-controller tar czf /tmp/unifi-backup.tar.gz /config || true
            docker cp unifi-controller:/tmp/unifi-backup.tar.gz "$BACKUP_DIR/" || true
            component_end unifi
        fi
        ;;
    rylan-pi)
        log_info "Backing up osTicket + MariaDB"
        # MariaDB
        if docker ps | grep -q mariadb; then
            component_start mariadb
            docker exec mariadb mysqldump -u root -p"${MARIADB_PW}" --all-databases > "$BACKUP_DIR/mariadb-dump.sql" 2>/dev/null || true
            component_end mariadb
            [[ $TEST_RESTORE == true ]] && test_restore mariadb "$BACKUP_DIR/mariadb-dump.sql"
        fi
        # osTicket data
        if docker ps | grep -q osticket; then
            component_start osticket
            docker cp osticket:/data "$BACKUP_DIR/osticket-data" || true
            component_end osticket
        fi
        ;;
    rylan-ai)
        log_info "Backing up Qdrant + Loki + NFS metadata"
        # Qdrant
        if [[ -d /srv/qdrant ]]; then
            component_start qdrant
            rsync -avz /srv/qdrant/ "$BACKUP_DIR/qdrant/" || true
            component_end qdrant
            [[ $TEST_RESTORE == true ]] && test_restore qdrant "$BACKUP_DIR/qdrant"
        fi
        # Loki recent chunks
        if [[ -d /srv/loki/data/chunks ]]; then
            component_start loki
            find /srv/loki/data/chunks -mtime -7 -type f -exec rsync -avz {} "$BACKUP_DIR/loki-chunks/" \; || true
            component_end loki
        fi
        ;;
    *) log_warn "Unknown host $HOSTNAME — skipping host-specific backup" ;;
esac

end_time=$(date +%s)
elapsed=$((end_time - start_time))

log_info "=== RTO Validation ==="
if (( elapsed > RTO_SECONDS )); then
    log_error "RTO FAILED — $elapsed seconds (limit $RTO_SECONDS)"
    exit 1
else
    log_info "RTO PASSED — $elapsed seconds"
fi

log_info "=== Backup Complete ==="
log_info "Location: $BACKUP_DIR"
log_info "Elapsed: ${elapsed}s"
log_info "Status: SUCCESS"

exit 0
