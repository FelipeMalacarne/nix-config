# ISSUE-045: Move Saradomin storage to ZFS with bounded datasets

- Status: needs-decision
- Priority: P2
- Kind: approved-direction storage redesign requiring a reinstall
- Scope: Saradomin disk layout, ZFS host configuration, K3s volume provisioning, snapshots, and migration
- Dependencies: would resolve [ISSUE-028](028-server-data-capacity.md) and the Saradomin part of [ISSUE-042](042-disko-device-safety.md); backup scope in [ISSUE-023](023-server-backup-coverage.md); restore drills in [ISSUE-026](026-restore-verification.md)

## Problem And Evidence

The [disk layout](../../hosts/saradomin/disk.nix) puts the operating system,
K3s state, container images, every PersistentVolume and the `/data` media
hostPath on one ext4 root filesystem. K3s's local-path provisioner maps each
PVC to a plain directory, so requested sizes are not enforced, volumes cannot
be expanded or snapshotted, and the default `Delete` reclaim policy removes data
with its claim.

Observed on 2026-10-26:

- In September 2026, media downloads filled the root filesystem and the kubelet
  evicted pods across `argocd`, `media`, `networking` and `observability` at the
  K3s default `nodefs.available<5%` threshold.
- Root was 71% used, with `/data` at about 267 GB (downloads and media 169 GB,
  Switch library 99 GB) and the Nix store at about 6 GB.
- The installed SSD now enumerates as `sdb` and an unrelated old HDD as `sda`,
  while `disk.nix` still declares `device = "/dev/sda"`. Booting works through
  partition labels, but running Disko against this configuration today would
  target the HDD.
- The HDD (320 GB, 5400 rpm, previously Windows, data disposable) passed SMART
  with zero reallocated, pending and uncorrectable sectors, about 7,900 power-on
  hours and an 87 MB/s sequential read. An extended self-test is pending.
- The resolved ZFS module for the current kernel (6.18) is `zfs_2_4` 2.4.4
  and is not marked broken.

## Proposed Design

### Disks

Address both disks by SATA port under `/dev/disk/by-path` rather than by kernel
name. `by-id` would publish serial numbers in this public repository. Recheck
the port mapping on the host before any destructive step.

SSD layout through Disko:

| Partition | Size | Use |
|---|---|---|
| ESP | 1G | `/boot` (vfat) |
| swap | 8G | plain swap partition; never swap on a zvol |
| `rpool` | remainder | ZFS pool |

`rpool` uses `ashift=12`, `compression=lz4`, `atime=off`, `xattr=sa` and
`acltype=posixacl`. Datasets:

| Dataset | Mountpoint | Properties | Snapshots |
|---|---|---|---|
| `rpool/root` | `/` | | yes |
| `rpool/nix` | `/nix` | | no |
| `rpool/var` | `/var/lib` | | yes |
| `rpool/rancher` | `/var/lib/rancher` | | no |
| `rpool/k8s` | none | `quota=120G`; parent of PVC datasets | yes, recursive |
| `rpool/data` | `/data` | `quota=280G`, `recordsize=1M` | no |
| `rpool/reserved` | none | `refreservation=30G`, never written | no |

Quotas are limits, not reservations, so their sum may exceed the pool. The
empty `rpool/reserved` keeps the pool from reaching 100%; lowering its
reservation is the emergency release valve. The current 267 GB of `/data` fits
under 280G only tightly, so download retention should be configured on the
media applications.

The HDD becomes a single-disk pool `tank`. It holds migration staging first,
then syncoid replicas, and is never the only copy of valuable data.

### Host Configuration

- `boot.supportedFilesystems = [ "zfs" ]` and a generated, stable
  `networking.hostId`.
- Cap the ARC at about 3 GiB with `zfs.zfs_arc_max` so pods keep most of the
  16 GB of RAM.
- `services.zfs.autoScrub` and `services.zfs.trim` for `rpool`.
- sanoid: hourly and daily snapshots of `rpool/root`, `rpool/var` and,
  recursively, `rpool/k8s`.
- syncoid: replicate those datasets from `rpool` to `tank`.
- `services.smartd` for both disks, plus an APM setting such as
  `hdparm -B 254` on the HDD to stop constant head parking.
- K3s flags: `--disable=local-storage` once no PVC uses local-path.

### Kubernetes (gielinor repository)

- Install OpenEBS ZFS LocalPV as a K3s `HelmChart`, pinned to a current
  release at implementation time.
- StorageClasses (all with `provisioner: zfs.csi.openebs.io`,
  `poolname: rpool/k8s`, `fstype: zfs`, `thinprovision: "yes"`,
  `allowVolumeExpansion: true`, `volumeBindingMode: WaitForFirstConsumer`):
  - `zfs` (default class): `recordsize: 128k`, `reclaimPolicy: Retain`.
  - `zfs-db`: `recordsize: 16k`, `reclaimPolicy: Retain`, for CNPG.
- Optionally deploy the snapshot controller and a `VolumeSnapshotClass` for
  CNPG volume-snapshot backups.
- Replace `local-path` in `apps/postgres/cluster.yaml`,
  `apps/filebrowser/pvc.yaml`, `infrastructure/observability/helmchart.yaml`
  (Grafana, Prometheus) and `infrastructure/observability/loki.yaml`, and set
  explicit classes where charts relied on the cluster default.
- Media hostPaths stay on `/data` and need no manifest change.

PVCs then grow online by raising `spec.resources.requests.storage`; the driver
raises the dataset quota. Shrinking is not possible. StatefulSet claims
(Prometheus, Loki) are patched directly and their chart values updated to
match; CNPG resizes from `spec.storage.size`.

## Decision And Scope

Direction approved on 2026-10-26: ZFS root on the SSD, OpenEBS ZFS LocalPV
for PVCs, and the HDD for staging and local replicas.

Decided on 2026-10-26:

- Root on ZFS, as in the dataset table.
- zram (`zstd`, about 25% of RAM, priority 100) as primary swap, keeping the
  8G swap partition at lower priority as a last resort. The partition must be
  created now because the pool cannot shrink later. Under Kubernetes 1.35
  defaults, pods do not swap; host services such as K3s, containerd, AdGuard
  and ai-memory do.

Still to decide:

- Final `rpool/data` and `rpool/k8s` quotas.
- Whether to preserve the K3s CA (`server/tls` and token) so existing
  kubeconfigs remain valid, or regenerate them.

Each destructive step below requires its own explicit approval at execution
time. This issue does not authorize any of them.

## Migration Runbook

1. Confirm the HDD extended self-test completed without error, then recheck
   by-path mapping and the SSD and HDD models.
2. Wipe the HDD and create a temporary staging filesystem or `tank`.
3. Stage critical host state onto the HDD and an independent offsite copy:
   `/var/lib/sops-age/keys.txt`, `/etc/ssh/ssh_host_*`, Tailscale state,
   AdGuard, ai-memory, and K3s `server/tls` plus `server/token` if the CA is
   kept.
4. Back up PostgreSQL logically (CNPG backup or `pg_dump`) and copy every
   local-path PVC directory with its namespace and claim name. Prometheus and
   Loki data are optional. Copy `/data` only if wanted and space allows.
5. Implement and build the new Disko, ZFS, sanoid, syncoid and K3s
   configuration; review the closure before installation.
6. Reinstall the SSD with Disko or nixos-anywhere from a known-good boot medium,
   then restore host state before the first K3s start.
7. Start K3s, deploy OpenEBS and the StorageClasses, then
   `make apply CLUSTER=saradomin` from gielinor.
8. Per application: let the new PVC bind, scale to zero, rsync the staged data
   into the mounted dataset preserving ownership, scale up and verify.
   Restore CNPG from its backup.
9. Convert the HDD to `tank` if it was used as plain staging, then enable
   syncoid and confirm the first replication.

## Acceptance Criteria

- [ ] Disko addresses every disk by stable path, and the SSD target is verified on the host.
- [ ] `/data`, PVCs and system datasets have enforced limits and a reserved free-space margin.
- [ ] All PVCs use OpenEBS ZFS LocalPV; local-path is disabled with no claims left on it.
- [ ] A PVC expansion succeeds online on a disposable claim.
- [ ] sanoid snapshots and syncoid replication to `tank` are running, and one PVC restore from a snapshot has been tested.
- [ ] Critical host state and the CNPG database survived migration and services are verified.

## Verification And Approval

Before any host change, finish formatting, evaluation and the Saradomin closure
build, and render the affected gielinor kustomizations and the cluster root.
A VM install of the Disko layout (for example `saradomin-vm`) is a useful
non-destructive dry run. HDD wiping, reinstalling, data migration, K3s
re-bootstrap and credential handling are not authorized by this issue.

## Resolution

Not resolved.

[Back to backlog](README.md)
