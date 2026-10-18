# ISSUE-026: Verify restores and independent recovery credentials

- Status: deferred
- Priority: P1
- Kind: explicitly deferred operational recovery verification
- Scope: Restore runbooks, representative recovery drills, and credential independence
- Dependencies: chosen scope from [ISSUE-023](023-server-backup-coverage.md), [ISSUE-024](024-hermes-state-backups.md), and [ISSUE-025](025-dark-souls-backups.md)

## Problem And Evidence

The [Restic feature](../../modules/features/services/restic.nix) declares backup
paths, runtime credential files, retention, and scheduling. The
[Makefile](../../Makefile) provides snapshot and restore commands, but command
availability and successful builds do not establish that useful data is restorable.

[Repository guidance](../../README.md#validation-and-deferred-work) and
[AGENTS.md](../../AGENTS.md#validation-and-deployment) explicitly defer
backup/restore verification. Recovery also needs repository access, decryption
material, and bootstrap instructions independently of the machine being lost.
No failed restore or missing recovery credential has been demonstrated here.

## Decision And Scope

After dataset decisions, agree recovery objectives, representative snapshots,
and a staged drill plan. Document how an authorized recovery operator obtains
credentials without depending solely on the failed host or its own backup.
Keep credential values and personal identifiers out of runbooks and issues.
Start in a new isolated destination; never overwrite original data or restore
into live databases, homes, volumes, or save directories to demonstrate success.

## Acceptance Criteria

- [ ] A reviewed runbook covers independent credentials, prerequisites, and isolated destinations.
- [ ] Approved representative restores demonstrate integrity, metadata, and usable application data.
- [ ] Database, token, and workload recovery requirements match the chosen backup scope.
- [ ] Measured recovery results, failures, and untested cases are recorded without secrets.
- [ ] Original data is preserved and any production recovery remains a separate approved action.

## Verification And Approval

Review the plan and exercise only disposable offline fixtures until explicit
approval names the real repository, snapshot, destination, and permitted actions.
Listing snapshots, checking repositories, reading recovery credentials, running
backups/restores, pruning, stopping services, or contacting remote storage are
operational actions and are not authorized here. A configuration build is not
restore evidence; keep this deferred until an approved drill supplies results.

## Resolution

Not resolved.

[Back to backlog](README.md)
