# ISSUE-017: Remove conflicting skhd shortcuts

- Status: open
- Priority: P2
- Kind: Source-confirmed duplicate bindings and inconsistent navigation
- Scope: MacBook skhd shortcut assignments and move-and-focus behavior
- Dependencies: User choice of replacement chords; native checks in ISSUE-038

## Problem And Evidence

The [skhd configuration](../../modules/features/desktop/darwin/skhd.nix#L10-L32)
assigns `Alt+Shift+W` to both application quit and upward resize. It also assigns
`Alt+Shift+X` to mirror the space and later to move a window to the next space.
The [space bindings](../../modules/features/desktop/darwin/skhd.nix#L54-L73)
repeat the identical `Alt+4` entry at lines 58-59. Pinned skhd 0.3.9 retains the
first duplicate, so later conflicting actions are unreachable, not combined.

At line 64, `Alt+Shift+Z` moves a window to `next` but focuses `prev`. A user
expecting to follow that window instead navigates away. These are source-level
findings, not evidence of observed application closure or lost work.

## Decision And Scope

Agree distinct chords for quit, resize, mirror, and move-and-follow actions.
Remove the identical duplicate and make previous/next movement agree with the
intended focus direction. Keep unrelated shortcuts intact; do not treat the
existing service-restart chord as permission to execute it.

## Acceptance Criteria

- [ ] Every effective chord has one intentional action, without duplicate entries.
- [ ] Quit, resize, mirror, and move actions have distinct documented assignments.
- [ ] Previous/next move-and-follow commands target the same intended space.
- [ ] A generated-config check catches duplicate chords and direction regressions.

## Verification And Approval

When implementation is separately approved, inspect the generated skhd config
and the pinned parser's behavior, then run formatting, evaluation, and a native
Apple-Silicon MacBook closure build. Use mocked command capture where possible;
real key injection, application quit, window movement, TCC changes, and service
restarts require separate approval under [ISSUE-038](038-native-darwin-validation.md).
No runtime action or configuration implementation is authorized by this entry.

## Resolution

Not resolved.

[Back to backlog](README.md)
