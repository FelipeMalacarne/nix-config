# ISSUE-012: Choose a consistent SOPS editing and key-access workflow

- Status: needs-decision
- Priority: P2
- Kind: source-confirmed bootstrap permission mismatch and ownership decision
- Scope: NixOS SOPS editing documentation and age-key directory access
- Dependencies: none; Darwin bootstrap remains separate as ISSUE-043

## Problem And Evidence

The [bootstrap instructions](../../README.md#setup-and-secrets) create a
root-owned `0700` key directory and a `0600` key, then invoke `make secrets`
without privilege escalation. The [Make target](../../Makefile) invokes SOPS
directly as the caller.

The [SOPS feature](../../modules/features/system/sops.nix) points the editing
environment at that key and uses a tmpfiles `z` rule to change the file's owner.
It does not grant traversal through the parent directory. On a fresh bootstrap,
file ownership alone therefore does not make the key usable by an ordinary user.
Existing machines may have different permissions; none were inspected here.

## Decision And Scope

Choose deliberately between privileged editing and controlled user access to
the age key. Make bootstrap, directory traversal, file ownership, and the editing
command agree with that policy. Keep the key private; do not solve traversal by
making secrets broadly readable or by copying keys into the repository/store.
This issue does not authorize changing password-hash policy or Darwin bootstrap.

## Acceptance Criteria

- [ ] The intended editor identity and privilege boundary are documented explicitly.
- [ ] Fresh bootstrap and steady-state permissions support that workflow consistently.
- [ ] Unintended users cannot traverse to or read the key under the selected policy.
- [ ] README instructions, Make behavior, and module permissions agree without secret disclosure.

## Verification And Approval

After the policy decision, validate directory traversal and editor identity with
dummy keys and disposable directories only. For an authorized configuration
change, complete formatting, evaluation, and affected NixOS closure builds.
Real key reads, decryption, ownership/mode changes, privileged editing, or
activation require explicit approval and are not part of documenting this issue.
Do not capture key contents or personal recipient identifiers as evidence.

## Resolution

Not resolved.

[Back to backlog](README.md)
