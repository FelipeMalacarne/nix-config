# ISSUE-025: Decide and configure Dark Souls III save backup coverage

- Status: needs-decision
- Priority: P2
- Kind: pre-existing user task and backup-scope decision
- Scope: Zaros game saves and Restic path selection
- Dependencies: none for the coverage decision and configuration

## Problem And Evidence

The existing [todo note](../todo.md) lists two candidate Dark Souls III save
locations. [Zaros's declared backup paths](../../hosts/zaros/default.nix) do not
include them. The note alone does not establish which installation is active,
whether both datasets matter, or whether an external backup already covers them.

## Decision And Scope

Confirm the active save roots and desired retention with the user. Preserve the
original note until its candidates have been evaluated; do not duplicate account
identifiers or save contents in issue documents. Select the useful paths through
the existing [Restic feature](../../modules/features/services/restic.nix).
Track operational recovery evidence separately in
[ISSUE-026](026-restore-verification.md); this decision need not wait for that drill.

## Acceptance Criteria

- [ ] Active save locations and any intentionally excluded installation are recorded without private save contents.
- [ ] The selected save roots are covered by the intended backup configuration.
- [ ] Missing or moved save paths have an explicit failure/monitoring policy.
- [ ] Backup and restore evidence is recorded, or remains explicitly pending in ISSUE-026.

## Verification And Approval

Inspect generated backup path configuration and build Zaros. Use disposable
save-shaped fixtures for offline tests. Running a real backup, stopping a game,
or restoring files requires approval; never overwrite active saves to demonstrate
recovery. Do not mark the operational coverage verified from a successful Nix
build alone.

## Resolution

Not resolved.

[Back to backlog](README.md)
