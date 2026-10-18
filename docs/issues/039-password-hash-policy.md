# ISSUE-039: Review ownership of account password hashes and recovery policy

- Status: deferred
- Priority: P1
- Kind: pre-existing identity-policy and recovery review
- Scope: shared NixOS account policy and intentional host overrides
- Dependencies: coordinate with [ISSUE-012](012-sops-editing-permissions.md) and [ISSUE-040](040-ssh-firewall-policy.md)

## Problem And Evidence

[Shared NixOS core](../../modules/features/system/core/config/nixos.nix) owns a
fixed user password-hash declaration inherited by hosts using base. Whether this
belongs in shared policy, host identity, or a runtime secret mechanism remains
an explicit deferred topic in [AGENTS.md](../../AGENTS.md) and the
[README](../../README.md). This does not establish a weak password or a successful
unauthorized login, and hash values must not be copied into this issue.

## Decision And Scope

Agree on intended cross-host identity, credential ownership, bootstrap, rotation,
and recovery requirements. Evaluate account locking and console/SSH interactions
before proposing implementation. Do not rotate, remove, relocate, or change
password-hash precedence as part of routine refactoring or other backlog issues.

## Acceptance Criteria

- [ ] The owner and lifecycle of password credentials are explicitly agreed.
- [ ] Per-host/shared behavior and fresh-install bootstrap requirements are documented.
- [ ] A recovery path is reviewed before any credential or account-locking change.
- [ ] Approved implementation has offline module tests and separately approved access verification.

## Verification And Approval

Inspect option ownership and generated account policy without exposing hash
values or reading decrypted credentials. Use isolated fixtures for module tests.
Any real credential, account, login, or activation change requires explicit user
approval and a recovery plan. Existing host access must not be tested by locking
the current user out or replacing working credentials.

## Resolution

Not resolved.

[Back to backlog](README.md)
