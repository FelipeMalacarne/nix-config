# ISSUE-024: Decide backup coverage for mutable Hermes state

- Status: needs-decision
- Priority: P2
- Kind: repository-confirmed path omission and data-value decision
- Scope: Zaros Hermes learning, sessions, writable skills, and credential exclusions
- Dependencies: none for the coverage decision and configuration

## Problem And Evidence

[Zaros's Restic paths](../../hosts/zaros/default.nix) cover selected documents
and game data, not the Hermes home. The
[Hermes feature](../../modules/features/programs/hermes-agent.nix) enables memory
and profile learning, while its activation seeds a skill only when absent.

The [writable-learning contract](../hermes-agent.md#writable-learning) preserves
runtime skills, memories, and OAuth state rather than replacing them on rebuild.
Sessions and learned improvements therefore cannot all be recovered from Nix
configuration alone. External backup coverage and the value of existing state
are unknown; no runtime files were inspected.

## Decision And Scope

Choose valuable memories, sessions, writable skills, and active profile data
with the user. Separate durable learning from caches, checkpoints, generated
tokens, and other reproducible material. Decide explicitly whether credentials
and `.env` are excluded, separately protected, or included under an approved
encrypted recovery policy. Do not back up the whole home indiscriminately.
Consider consistency requirements for any live session database before capture.
Track operational recovery evidence in [ISSUE-026](026-restore-verification.md)
without making this scope decision depend on a completed restore drill.

## Acceptance Criteria

- [ ] Valuable Hermes datasets and active-profile scope have explicit inclusion decisions.
- [ ] Credential, token, cache, and checkpoint handling is documented without revealing contents.
- [ ] Approved Restic paths/exclusions and retention cover the chosen durable state.
- [ ] Mutable databases have a consistent capture method and restore requirements for ISSUE-026.

## Verification And Approval

For an authorized implementation, inspect generated path/exclusion configuration
and test representative disposable state, including credential-shaped exclusions.
Complete formatting, evaluation, relevant checks, and the Zaros closure build.
Do not read real learning, sessions, credentials, or `.env` for this documentation
task. Real backups, service stops, credential changes, activation, and recovery
tests require explicit approval; never overwrite the active Hermes home.

## Resolution

Not resolved.

[Back to backlog](README.md)
