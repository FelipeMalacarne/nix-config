# ISSUE-035: Plan and validate a controlled core input update

- Status: needs-decision
- Priority: P2
- Kind: maintenance and version-selection decision
- Scope: Nixpkgs, Home Manager, nix-darwin, Stylix, and affected integration pins
- Dependencies: [ISSUE-001](001-clean-flake-sources.md), [ISSUE-002](002-desktop-selection-checks.md)

## Problem And Evidence

The reviewed [lock file](../../flake.lock) used a main Nixpkgs revision from
August 26 while newer unstable revisions were available. Several supporting
inputs were older too. This is an update opportunity, not proof that every pin
is insecure or that the newest combination is compatible. The
[flake declaration](../../flake.nix) intentionally preserves Hermes's separate
Nixpkgs pin for its Electron/header checksum pairing.

## Decision And Scope

Choose a small, reviewable update batch after restoring green baseline checks.
Read current release/module changes and record intentional pins before updating.
Do not blindly update every input, force all dependencies to follow one Nixpkgs,
or bump `stateVersion` merely to match the current release. Handle new functional
regressions separately rather than hiding them among lock changes.

## Acceptance Criteria

- [ ] The chosen inputs, target revisions, compatibility notes, and intentional exclusions are recorded.
- [ ] Lock changes contain only the intended update and necessary transitive changes.
- [ ] Formatting, full evaluation, relevant checks, and affected native closure builds pass.
- [ ] Remaining runtime risks and the approved recovery/trial plan are documented before deployment.

## Verification And Approval

Use the restored full check path, build all affected NixOS closures, and obtain
native Apple-Silicon verification for Darwin changes. Read upstream warnings
before replacing deprecated options. Builds do not authorize activation, boot,
reboot, logout, remote deployment, or session-interrupting restarts. Coordinate
approved runtime evidence with [ISSUE-037](037-native-desktop-validation.md) and
[ISSUE-038](038-native-darwin-validation.md).

## Resolution

Not resolved.

[Back to backlog](README.md)
