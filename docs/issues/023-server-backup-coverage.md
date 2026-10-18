# ISSUE-023: Decide server backup coverage and consistency

- Status: needs-decision
- Priority: P1
- Kind: repository-confirmed coverage gap and recovery-scope decision
- Scope: Saradomin and server-VM mutable data, retention, and backup ownership
- Dependencies: none for the coverage decision and configuration

## Problem And Evidence

Neither [Saradomin](../../hosts/saradomin/default.nix) nor its
[VM variant](../../hosts/saradomin-vm/default.nix) selects the
[Restic feature](../../modules/features/services/restic.nix). The
[server profile](../../modules/profiles/server.nix) does not import it either.
This repository therefore does not declare server backup coverage; external
application backups or independently managed jobs remain unknown, not disproven.

Saradomin's [K3s feature](../../modules/features/services/k3s.nix) enables a
server and creates mutable media/download directories. Recovery planning must
consider its datastore, server token, workload volumes, valuable `/data` content,
and AdGuard state, rather than treating a Nix rebuild as a data backup.
Blind copying of a running SQLite datastore is not a consistency strategy.

## Decision And Scope

Inventory valuable versus reproducible data and confirm existing external
coverage with its owner. Choose recovery objectives, retention, destinations,
credentials, and application-consistent snapshot/export procedures. Distinguish
K3s control-plane recovery from workload-volume recovery and disposable media.
Keep host selection explicit; do not enable Restic for every server by default.
Hand off recovery evidence to [ISSUE-026](026-restore-verification.md) rather
than making the coverage decision depend on an already completed restore drill.

## Acceptance Criteria

- [ ] Each server dataset has an owner, recovery objective, and inclusion or exclusion decision.
- [ ] Existing external backups are confirmed or their uncertainty is explicitly recorded.
- [ ] Datastore, token, and volume capture use a documented, consistent recovery set.
- [ ] Selected backup configuration and failure monitoring match the approved policy.
- [ ] Restore requirements and remaining operational evidence are handed to ISSUE-026.

## Verification And Approval

After scope approval, validate generated paths, exclusions, schedules, and
consistency logic with disposable fixtures; complete formatting, evaluation,
and affected server closure builds for any configuration change. Real backup
runs, repository initialization/pruning, datastore access, workload stops,
credential handling, remote access, activation, and restores require explicit
approval. No operational backup action is authorized by this issue's creation.

## Resolution

Not resolved.

[Back to backlog](README.md)
