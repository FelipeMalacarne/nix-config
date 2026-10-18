# ISSUE-037: Perform an approved native desktop smoke test

- Status: deferred
- Priority: P1
- Kind: explicitly deferred native runtime validation; no reproduced outage
- Scope: Zaros's approved graphical login, locking, graphics, and recovery trial
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for baseline validation; [ISSUE-003](003-plain-hyprland-locking.md), [ISSUE-004](004-i3-selection-and-locking.md), and [ISSUE-008](008-noctalia-suspend-locking.md) for selected locking paths

## Problem And Evidence

[AGENTS](../../AGENTS.md#validation-and-deployment) and the
[README](../../README.md#validation-and-deferred-work) defer native NVIDIA, login,
monitor, suspend/resume, gaming, Xwayland, and portal tests pending approval.
Offline checks and built closures do not establish these physical-session properties.

The [desktop checks](../../modules/features/desktop/desktop/config/test_sessions.nix)
and [greeter checks](../../modules/features/desktop/desktop/config/test_greeter.nix)
cover composition, generated files, discovery, and mocked X11 routing, not physical
login. [Zaros's settings](../../hosts/zaros/desktop.nix) define the selected sessions.

## Decision And Scope

Remain deferred until the user approves a bounded controlled next-boot trial
with a known-good generation, available TTY recovery, and an agreed recovery plan.
Agree retained sessions/providers and test order first; review locking fixes
before any suspend test. Approval must identify the specific operational actions.

Preserve serial-bearing monitor identities, separate XRandR connectors, modes,
positions, rotations, and workspaces. A disconnected secondary remains untested.
Exercise Noctalia natively per compositor; do not wrap Umbriel in UWSM or introduce
provider-specific compositor coupling. Include [Lua](006-hyprland-lua-dispatch.md),
[locale](007-hyprland-locale.md), [DDC](009-noctalia-ddc-controls.md), and
[volume](010-noctalia-volume-action.md) follow-ups only as selected and approved.

## Acceptance Criteria

- [ ] Explicit trial/action approval, known-good generation, and TTY recovery plan are recorded.
- [ ] Formatting, evaluation, affected checks, and the Zaros closure build pass before the trial.
- [ ] Retained login/provider startup and manual/idle/pre-sleep/resume locking are tested safely.
- [ ] NVIDIA, connected-monitor topology, gaming, Xwayland, and portal results are recorded by scope.
- [ ] Recovery outcome, failures, and untested paths/displays remain explicit; missing evidence stays open.

## Verification And Approval

Prepare an offline matrix and record check/build evidence without touching the
session. Record the tested generation, session/provider, results, and limits;
omit private logs. No boot, reboot, logout, activation, rollback, greeter restart,
service/session action, suspend, or hardware operation is authorized here. Obtain
separate explicit approval; never substitute a live greeter restart for the trial.

## Resolution

Not resolved.

[Back to backlog](README.md)
