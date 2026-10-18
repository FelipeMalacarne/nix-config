# ISSUE-013: Make the base profile's secret dependency explicit

- Status: resolved
- Priority: P2
- Kind: reproduced module-composition failure
- Scope: base, SSH identity integration, and minimal feature fixtures
- Dependencies: none; key-access policy is separate in [ISSUE-012](012-sops-editing-permissions.md)

## Problem And Evidence

The [base profile](../../modules/profiles/base.nix) imports SSH integration whose
[NixOS registration](../../modules/features/programs/ssh.nix) declares
`sops.secrets` without introducing the upstream option definitions. Evaluating
a minimal base configuration without an additional SOPS import failed with
`The option sops does not exist` during review.

Existing hosts supply SOPS explicitly, so this is not a demonstrated current
host outage. The [test helper](../../modules/checks.nix) always injects SOPS,
which hides the dependency from otherwise minimal base/server fixtures.

## Decision And Scope

Choose explicit ownership for secret-backed identities. Prefer separating plain
SSH client policy from optional encrypted-identity integration if that preserves
the documented base contract. Do not silently enable unrelated integrations,
change SSH authentication policy, or alter key ownership as part of the refactor.

## Acceptance Criteria

- [ ] The supported minimal base composition evaluates under its documented contract.
- [ ] Required dependencies are explicit rather than supplied only by test scaffolding.
- [ ] Secret-backed SSH identities remain selected and configured on existing hosts.
- [ ] A regression fixture exercises base without the old unconditional SOPS injection.

## Verification And Approval

Evaluate minimal Home Manager activation packages as well as real host closures;
avoid confusing missing hardware/root-filesystem fixture facts with this module
failure. Run feature-import checks and all affected NixOS builds. Review Darwin
composition too if its registration changes. No activation, credential rotation,
SSH policy change, or decrypted-key inspection is authorized.

## Resolution

Already fixed: `ssh` no longer declares secrets; `ssh-credentials` imports SOPS itself and base imports only `ssh`.

[Back to backlog](README.md)
