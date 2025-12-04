---
title: HA Backup Scaling Guide
subtitle: Three deployment paths with Total Cost of Ownership analysis
version: 1.0
date: 2025-12-04
---

# HA Backup Scaling Guide — Eternal Fortress v1.1.2

## Executive Summary

This guide covers three architectural paths for scaling backup infrastructure in the Eternal Fortress ecosystem:
- **Path A (Small)**: Single NFS node, single backup destination, <15 min RTO
- **Path B (Medium)**: NFS cluster with replication, multi-region backup, <5 min RTO
- **Path C (Large)**: Full distributed backup with object storage, <60 sec RTO

Each path includes deployment steps, cost analysis, and RTO/RPO targets.

---

## Path A: Single-Node Backup (Small Deployments)

**Target:** <100 GB data, 1-3 hosts, office/branch location

### Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│ Three Backup Sources                                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  rylan-dc    │  │  rylan-pi    │  │  rylan-ai    │     │
│  │ (Samba/FR)   │  │ (osTicket)   │  │ (Qdrant)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                 │               │
│         └─────────────────┼─────────────────┘               │
│                           ▼                                 │
│         ┌──────────────────────────────────┐              │
│         │ NFS Backup Node (1x)             │              │
│         │ - Ubuntu 22.04 LTS              │              │
│         │ - 4 core / 16 GB RAM            │              │
│         │ - 1 TB SSD (local)              │              │
│         │ - 4 TB HDD (backup)             │              │
│         └──────────────────────────────────┘              │
│                           │                                 │
│                           ▼                                 │
│         ┌──────────────────────────────────┐              │
│         │ /srv/nfs/backups                 │              │
│         │ - Daily incremental (7 days)    │              │
│         │ - Weekly full (4 weeks)         │              │
│         └──────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

RTO: 15 min | RPO: 1 hour

### Deployment Steps

1. **Provision NFS backup node**

```bash
# Ubuntu 22.04 with 4 TB storage
# Minimum: 4 core, 16 GB RAM, 1 Gbps network

sudo apt update && sudo apt install -y nfs-kernel-server rsync
sudo mkdir -p /srv/nfs/backups
sudo chown nobody:nogroup /srv/nfs/backups
sudo chmod 777 /srv/nfs/backups
```

1. **Export NFS share**

```bash
echo '/srv/nfs/backups 192.168.1.0/24(rw,sync,no_subtree_check)' | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

1. **Configure cron on each source host**

```bash
# On rylan-dc, rylan-pi, rylan-ai
sudo crontab -e
# Add: 0 */6 * * * /path/to/orchestrator.sh >> /var/log/backup.log 2>&1
```

1. **Monitor with check-critical-services.sh**

```bash
# Verify backup freshness every 15 minutes
*/15 * * * * /03-validation-ops/check-critical-services.sh
```

### Cost Analysis (Path A)

| Component | Cost | Quantity | Total |
|-----------|------|----------|-------|
| NFS Backup Node (server) | $400 | 1 | $400 |
| Network Switch (managed) | $250 | 1 | $250 |
| Storage: 1 TB SSD | $80 | 1 | $80 |
| Storage: 4 TB HDD | $60 | 2 | $120 |
| UPS 1500W | $200 | 1 | $200 |
| Networking (cables, etc) | - | - | $50 |
| **Hardware Total** | | | **$1,100** |
| Annual Maintenance (15%) | - | - | $165 |
| Power/Cooling (annual) | $30/mo | 12 | $360 |
| **Total Year 1** | | | **$1,625** |
| **Annual (Y2+)** | | | **$525** |

**Break-even:** Cost-effective if <3 hosts. Beyond 3 hosts, consider Path B.

---

## Path B: NFS Cluster with Replication (Medium Deployments)

**Target:** 100 GB–1 TB data, 3-10 hosts, campus/datacenter

### Architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│ Three Backup Sources (rylan-dc, rylan-pi, rylan-ai)                 │
├──────────────────────────────────────────────────────────────────────┤
│          ┌────────────────┐        ┌────────────────┐               │
│          │   Primary NFS  │◄──────►│  Secondary NFS │               │
│          │    (Active)    │ Rsync  │   (Standby)    │               │
│          │ 8GB RAM / 2TB  │ Repl   │ 8GB RAM / 2TB  │               │
│          └────────────────┘        └────────────────┘               │
│                 ▲                           ▲                        │
│                 │ (Failover)                │                        │
│          All sources (3x)           Read-only copy                  │
│                 │                           │                        │
│         ┌───────┴───────────────────────────┴────────┐              │
│         │  rsync daemon (hourly)                    │              │
│         │  - Replication lag: <1 hr                 │              │
│         │  - Verified checksums                    │              │
│         └───────────────────────────────────────────┘              │
│                           │                                         │
│                           ▼                                         │
│         ┌─────────────────────────────────┐                        │
│         │ S3-compatible object storage    │                        │
│         │ (optional: weekly full backup)  │                        │
│         └─────────────────────────────────┘                        │
└──────────────────────────────────────────────────────────────────────┘
```

RTO: 5 min | RPO: 1 hour | Geo-redundancy: Yes

### Deployment Steps

1. **Provision two NFS nodes**

```bash
# Node 1: Primary (192.168.1.10)
# Node 2: Secondary (192.168.1.11)
# Both: 8 core, 8 GB RAM, 2 TB SSD

sudo apt install -y nfs-kernel-server rsync
sudo mkdir -p /srv/nfs/backups
```

1. **Set up replication via rsync daemon**

```bash
# On primary: /etc/rsyncd.conf
[backups]
  path = /srv/nfs/backups
  read only = false
  uid = nobody
  gid = nogroup

# On secondary: cron job
0 * * * * rsync -avz primary:/srv/nfs/backups/ /srv/nfs/backups/
```

1. **Configure failover via VIP (Virtual IP)**

```bash
# Install keepalived for HA
sudo apt install -y keepalived

# Primary: priority 100
# Secondary: priority 50
# VIP: 192.168.1.100 (floating IP)

# All sources use NFS mount to 192.168.1.100
mount -t nfs 192.168.1.100:/srv/nfs/backups /mnt/backups
```

1. **Add S3 mirror (weekly full backup)**

```bash
# Optional: MinIO or AWS S3
# Cron on secondary: weekly full sync to S3
0 2 * * 0 aws s3 sync /srv/nfs/backups s3://eternal-backups/ --delete
```

### Cost Analysis (Path B)

| Component | Cost | Quantity | Total |
|-----------|------|----------|-------|
| NFS Nodes (2x, 8 core, 8GB) | $800 | 2 | $1,600 |
| Network Switch (managed, LACP) | $500 | 1 | $500 |
| Storage: 2TB NVMe (per node) | $150 | 4 | $600 |
| UPS 3000W | $400 | 1 | $400 |
| Keepalived license | - | - | $0 |
| S3-compat storage (MinIO) | $1,000 | 1 | $1,000 |
| **Hardware Total** | | | **$4,100** |
| Annual Maintenance (20%) | - | - | $820 |
| Power/Cooling (annual) | $75/mo | 12 | $900 |
| S3 egress (100 GB/month) | $1/GB | 100 | $100 |
| **Total Year 1** | | | **$5,920** |
| **Annual (Y2+)** | | | **$1,820** |

**Break-even:** Pays for itself with 5+ hosts; justifies <5 min RTO requirement.

---

## Path C: Distributed Backup with Object Storage (Large Deployments)

**Target:** 1 TB–10 TB data, 10+ hosts, multi-site, enterprise SLA

### Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│ Multi-Site Backup Infrastructure                                       │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ ┌─ SITE A ─────────────────────┐    ┌─ SITE B ─────────────────────┐ │
│ │ Sources: rylan-dc, rylan-pi  │    │ Sources: rylan-ai (replica)  │ │
│ │ NFS Node (Primary)           │    │ NFS Node (Secondary)         │ │
│ │ ├─ S3-gateway (MinIO)        │    │ ├─ S3-gateway (MinIO)        │ │
│ │ └─ Qdrant (vectors)          │    │ └─ Qdrant (replica)          │ │
│ └─────────────────────────────┬┘    └──────────────────┬──────────┘ │
│                               │                        │             │
│                    ┌──────────┴────────────┐           │             │
│                    │   Global S3 Bucket    │◄──────────┘             │
│                    │  (AWS S3 or Wasabi)   │ Real-time repl          │
│                    │ - Hot: Recent (90d)   │                         │
│                    │ - Warm: 90d-1yr       │                         │
│                    │ - Cold: Archive       │                         │
│                    └───────────────────────┘                         │
│                               │                                      │
│                               ▼                                      │
│                    ┌───────────────────────┐                         │
│                    │ Disaster Recovery     │                         │
│                    │ - RTO: 60 sec         │                         │
│                    │ - RPO: Real-time      │                         │
│                    │ - Multi-site ready    │                         │
│                    └───────────────────────┘                         │
└────────────────────────────────────────────────────────────────────────┘
```

RTO: <60 sec | RPO: Real-time | Availability: 99.95%

### Deployment Steps

1. **Deploy at Site A (Primary)**

```bash
# NFS cluster (2 nodes) + MinIO S3 gateway
sudo apt install -y nfs-kernel-server minio

# MinIO config: /etc/minio/minio.env
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)
MINIO_VOLUMES=/mnt/data{1..4}
```

1. **Deploy at Site B (Secondary)**

```bash
# Mirror configuration
# NFS replicates from Site A every 15 minutes
# S3 bucket replicates in real-time via cross-region replication
```

1. **Configure S3 cross-region replication**

```bash
# On primary MinIO
mc mb --region us-east eternal-prod
mc version enable eternal-prod
mc replicate add eternal-prod --replicate-to arn:aws:s3:::eternal-prod-dr
```

1. **Implement real-time sync with Loki/Vector**

```yaml
# promtail-ai-config.yaml
clients:
  - url: https://loki.site-a.local/loki/api/v1/push
  - url: https://loki.site-b.local/loki/api/v1/push  # Async mirror
```

### Cost Analysis (Path C)

| Component | Cost | Quantity | Total |
|-----------|------|----------|-------|
| NFS Cluster (4 nodes, 2 per site) | $1,200 | 4 | $4,800 |
| MinIO S3 (enterprise, 2 sites) | $3,000 | 2 | $6,000 |
| Network: 10 Gbps pipes (2) | $500/mo | 24 | $12,000 |
| Managed S3 (AWS/Wasabi, 5 TB) | $115/mo | 12 | $1,380 |
| UPS (per site, 5 kVA) | $1,500 | 2 | $3,000 |
| Hardware total | | | **$27,180** |
| Annual support (SLA 99.95%) | 15% | $27,180 | $4,077 |
| Network egress (10 TB/mo) | $0.12/GB | 10000 | $1,200 |
| Power/Cooling (annual, 2 sites) | $150/mo | 24 | $3,600 |
| **Total Year 1** | | | **$36,257** |
| **Annual (Y2+, no HW)** | | | **$8,877** |

**Break-even:** 15+ hosts with strict SLA; enterprise customers only.

---

## Decision Matrix

| Factor | Path A | Path B | Path C |
|--------|--------|--------|--------|
| **Data Volume** | <100 GB | 100 GB–1 TB | 1–10 TB |
| **Host Count** | 1–3 | 3–10 | 10+ |
| **RTO Target** | 15 min | 5 min | <60 sec |
| **Failover** | Manual | Automatic (VIP) | Multi-site |
| **Year 1 Cost** | $1,625 | $5,920 | $36,257 |
| **Cost/Host/Year** | $542 | $592 | $3,626 |
| **Maintenance** | Simple | Moderate | Complex |
| **Team Size** | 1–2 | 2–3 | 3–5 |

---

## Migration Path

### Small → Medium (Path A → Path B)

**Trigger:** Data exceeds 100 GB OR RTO requirement drops to <5 min

**Steps:**
1. Deploy secondary NFS node in parallel (no downtime)
2. Configure rsync replication from primary
3. Install keepalived with VIP
4. Migrate sources to VIP mount point
5. Decommission single-node setup

**Downtime:** Zero (live migration)

### Medium → Large (Path B → Path C)

**Trigger:** Multi-site requirement OR 10+ hosts

**Steps:**
1. Deploy Site B infrastructure (parallel)
2. Replicate backups via S3 cross-region replication
3. Test failover procedure
4. Update disaster recovery runbook
5. Gradual traffic cutover per host

**Downtime:** Zero (gradual migration)

---

## Operational Runbooks

### Daily Backup Verification

```bash
#!/bin/bash
# Daily: verify all backups completed in last 24 hours
for host in rylan-dc rylan-pi rylan-ai; do
  last_backup=$(stat -c %Y /srv/nfs/backups/$(date +%Y%m%d)*_$host 2>/dev/null | head -1)
  now=$(date +%s)
  age=$((now - last_backup))
  if (( age > 86400 )); then
    alert "Backup stale for $host: ${age}s old"
  fi
done
```

### Restore Procedure (Path A)

```bash
# Example: Restore Samba from 2025-12-03 backup
BACKUP_DATE=20251203
cd /srv/nfs/backups/${BACKUP_DATE}_*_rylan-dc/samba
rsync -avz ./ root@rylan-dc:/var/lib/samba/ --backup-dir=/var/lib/samba.bak
systemctl restart smbd
```

### Failover Procedure (Path B/C)

```bash
# Keepalived handles automatic VIP failover
# Manual verification:
ip addr show | grep 192.168.1.100
# If on secondary, primary has failed
# Promote secondary to primary in MinIO replication
```

---

## References

- [ROADMAP.md](../ROADMAP.md) — Phase 3 endgame timeline
- [orchestrator.sh](../03-validation-ops/orchestrator.sh) — Automated backup runner
- [check-critical-services.sh](../03-validation-ops/check-critical-services.sh) — Health monitoring
- [backup-cron.sh](../03-validation-ops/backup-cron.sh) — Cron job wrapper

---

**Document Version:** 1.0
**Last Updated:** 2025-12-04
**Next Review:** 2026-03-04
**Owner:** Infrastructure Team
