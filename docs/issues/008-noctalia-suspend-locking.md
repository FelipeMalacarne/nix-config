# ISSUE-008: Use Noctalia's lock-ready suspend action

- Status: in-progress
- Priority: P2
- Kind: source-confirmed action-path mismatch; unlocked resume not reproduced
- Scope: Noctalia session-menu suspend action and lock-readiness coverage
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for validation; coordinate lifecycle coverage with [ISSUE-003](003-plain-hyprland-locking.md)

## Problem And Evidence

The [lockscreen settings](../../modules/features/desktop/noctalia/config/settings.toml#L107-L112)
enable `lock_before_suspend`, but the
[session action](../../modules/features/desktop/noctalia/config/settings.toml#L187-L190)
selects `suspend`. Review of the pinned native shell established that this action
bypasses its lock-ready handshake; `lock_and_suspend` provides that path.

The [Hypridle pre-sleep hook](../../modules/features/desktop/hyprland/config/hyprland.nix#L117-L121)
and [Umbriel idle integration](../../modules/features/desktop/umbriel/config/home.nix#L201-L219)
may provide external protection when their session services are active. The
finding is an avoidable gap in the menu action's own ordering guarantee, not
proof that the current host resumes unlocked.

## Decision And Scope

Use the pinned Noctalia action that waits for lock readiness before suspending.
Keep the existing shortcut and countdown unless an explicit UX decision changes
them. Do not replace the native handshake with a shell command plus a fixed delay.

Keep compositor idle hooks provider-neutral and session-scoped; they remain
defense in depth rather than a reason to bypass the native action. Review merged
settings as well as the baseline because [saved GUI settings](../../README.md#noctalia-ui-workflow)
can override declarative preferences. Do not reset live user state without approval.

## Acceptance Criteria

- [ ] The declared suspend menu entry uses the pinned lock-ready action.
- [ ] Countdown and shortcut behavior remain intentional and the native schema accepts the action.
- [ ] Offline tests assert the action choice and lock-before-suspend policy together.
- [ ] Saved overrides are considered without silently overwriting the user's live settings.
- [ ] Approved native tests confirm the scoped lock-before-sleep and locked-resume behavior.

## Verification And Approval

After implementation, run formatting, evaluation, native Noctalia config and
export checks, and the affected Zaros closure build. Configuration validation
does not exercise the real lock-ready/sleep sequence. Coordinate retained login
paths with [ISSUE-004](004-i3-selection-and-locking.md); physical Noctalia tests
belong to [ISSUE-037](037-native-desktop-validation.md). No suspend, logout,
activation, greeter restart, or service/session action is authorized here.

## Resolution

Changed the Noctalia session action from `suspend` to `lock_and_suspend` in `settings.toml`. `noctalia-export` now asserts `lock_before_suspend` is set and the session menu uses `lock_and_suspend` and not `suspend`. Evaluation checks pass. Open: native suspend/resume test under ISSUE-037.

[Back to backlog](README.md)
