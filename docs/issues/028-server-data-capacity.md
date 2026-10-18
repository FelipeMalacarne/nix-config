# ISSUE-028: Bound server media and download capacity

- Status: needs-decision
- Priority: P2
- Kind: source-confirmed shared-capacity risk with unmeasured runtime usage
- Scope: Saradomin root capacity, media/download growth, and alerting policy
- Dependencies: data-value decisions in [ISSUE-023](023-server-backup-coverage.md); disk safety in [ISSUE-042](042-disko-device-safety.md)

## Problem And Evidence

The [disk layout](../../hosts/saradomin/disk.nix) assigns the remaining disk to
the root filesystem and declares no separate `/data` filesystem. The
[K3s feature](../../modules/features/services/k3s.nix) creates media and complete/
incomplete download directories beneath `/data`, without capacity bounds here.

As declared, growing downloads and media share capacity with operating-system,
K3s, and AdGuard state. Exhaustion could impair those services even when the
media itself is disposable. This is a configuration-level risk, not evidence
that the disk is currently full; usage and external workload limits are unknown.

## Decision And Scope

Start with agreed free-space thresholds, ownership, and actionable alerts.
Identify retention and incomplete-download cleanup policies without assuming
all workload volumes are disposable. Then decide whether application limits,
quotas, or separate storage are justified. Coordinate valuable-data decisions
with backup scope before proposing cleanup or migration.
Any quota, storage-layout, or Disko change requires separate explicit approval.

## Acceptance Criteria

- [ ] Capacity thresholds and alert destinations preserve headroom for essential services.
- [ ] Media/download owners and external workload limits are documented or explicitly unknown.
- [ ] Retention and cleanup rules distinguish reproducible content from valuable state.
- [ ] Any proposed quota or storage change includes approved migration and recovery safeguards.

## Verification And Approval

Review declared mounts and proposed alert logic first; use disposable fixtures
to test thresholds without filling a real filesystem. For authorized Nix
changes, complete formatting, evaluation, and the Saradomin closure build.
Runtime usage probes, cleanup, volume pruning, quota changes, data migration,
partitioning, and Disko execution are not authorized here. Never indiscriminately
prune workload volumes or intentionally exhaust the server to test protection.

## Resolution

Not resolved.

[Back to backlog](README.md)
