# ISSUE-042: Review Disko device-selection safety

- Status: deferred
- Priority: P1
- Kind: explicitly deferred destructive-operation safety assessment
- Scope: Saradomin Disko target identity, operator guards, and recovery prerequisites
- Dependencies: coordinate valuable-data and recovery decisions in [ISSUE-023](023-server-backup-coverage.md)

## Problem And Evidence

[Saradomin's host](../../hosts/saradomin/default.nix) imports the
[Disko layout](../../hosts/saradomin/disk.nix), which selects `/dev/sda` and
defines GPT partitions, boot, swap, and root filesystems. A kernel device name
alone does not establish a stable physical-device identity across environments.

The source has not been compared with actual device identity, inventory, or
operator tooling. There is no evidence here that the configured target is wrong
or that a destructive command has run. [README](../../README.md#validation-and-deferred-work)
and [AGENTS.md](../../AGENTS.md#validation-and-deployment) explicitly defer Disko
device safety rather than authorizing installation or repartitioning work.

## Decision And Scope

Assess the intended device, stable identity options, installation environment,
and safeguards against selecting an unrelated disk. Document preflight checks,
operator confirmation, data recovery prerequisites, and the difference between
evaluating a layout and executing destructive provisioning. Do not invent a
device identifier or assume that a different pathname alone proves safety.
Any layout/target change needs explicit approval, even if execution is deferred.

## Acceptance Criteria

- [ ] The intended physical target and proposed identity checks are reviewed without publishing identifiers.
- [ ] Operator guards reject ambiguous or unexpected targets before destructive execution.
- [ ] Recovery prerequisites and the exact separately approved installation scope are documented.
- [ ] Assessment results distinguish source review, mocked checks, and unperformed hardware validation.

## Verification And Approval

Begin with source review and a non-executing preflight design. If implementation
is separately approved, use disposable fixtures for guards and complete required
formatting, evaluation, and affected closure builds without provisioning disks.
Hardware enumeration, target changes, partitioning, formatting, wiping, Disko
execution, installation, and deployment are not authorized here. Never run a
destructive command as a safety test or treat a successful build as target proof.

## Resolution

Not resolved.

[Back to backlog](README.md)
