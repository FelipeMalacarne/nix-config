# ISSUE-003: Cover the plain Hyprland login path with locking

- Status: open
- Priority: P1
- Kind: source-confirmed lifecycle gap; runtime exposure unverified
- Scope: Hyprland login discovery, idle locking, and session lifecycle
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for trustworthy validation

## Problem And Evidence

The [Hypridle configuration](../../modules/features/desktop/hyprland/config/hyprland.nix#L113-L132)
attaches locking, pre-sleep locking, and DPMS listeners to
`wayland-session@hyprland.desktop.target`. That target belongs to the UWSM
session lifecycle, not the raw `hyprland.desktop` login path.

The [session checks](../../modules/features/desktop/desktop/config/test_sessions.nix#L177-L202)
retain both `hyprland` and `hyprland-uwsm`, and the
[greeter projection](../../modules/features/desktop/noctalia-greeter.nix#L43-L63)
copies the Wayland entries. Plain Hyprland remains advertised without starting
the target that owns these protections. No physical unlocked-resume test was run.

## Decision And Scope

Hide the unsupported plain entry from greeter discovery, or deliberately support
its startup, idle, lock, and teardown lifecycle. Do not delete the backing
`hyprland.desktop`: UWSM requires it to launch the managed session. Verify the
chosen discovery mechanism against the pinned greeter rather than assuming a
desktop-file visibility flag is honored.

Keep compositor integration provider-neutral and preserve Umbriel's independent
native lifecycle. Coordinate suspend coverage with
[ISSUE-008](008-noctalia-suspend-locking.md), without treating that action fix as
a substitute for starting the correct idle service.

## Acceptance Criteria

- [ ] Every advertised Hyprland login path has an explicit supported lifecycle.
- [ ] UWSM's backing desktop entry remains available and managed login still resolves.
- [ ] Unsupported plain login is hidden, or its lock/idle service starts and stops correctly.
- [ ] Offline discovery and lifecycle tests cover the choice without changing monitor topology.
- [ ] Approved native tests confirm locking for the retained advertised paths.

## Verification And Approval

After implementation, run formatting, evaluation, desktop/greeter checks, and the
affected Zaros closure build. Inspect generated entries and service relationships
offline; those checks do not establish physical locking. Native login, idle, and
suspend tests belong to [ISSUE-037](037-native-desktop-validation.md). No activation,
logout, reboot, greeter restart, or service/session action is authorized here.

## Resolution

Not resolved.

[Back to backlog](README.md)
