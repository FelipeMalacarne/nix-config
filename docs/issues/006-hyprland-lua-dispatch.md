# ISSUE-006: Replace legacy dispatch commands in Hyprland Lua

- Status: in-progress
- Priority: P2
- Kind: source-confirmed command incompatibility with the pinned Lua manager
- Scope: Hyprland next-monitor movement and keyboard resizing bindings
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for trustworthy validation

## Problem And Evidence

The [next-monitor binding](../../modules/features/desktop/hyprland/config/hyprland.lua#L71)
executes `hyprctl dispatch movewindow mon:+1`. The
[resize loop](../../modules/features/desktop/hyprland/config/hyprland.lua#L76-L78)
similarly executes legacy `resizeactive` commands. Review against pinned
Hyprland 0.56.2 established that these legacy dispatcher names are incompatible
with its Lua configuration manager.

Other bindings already construct `hl.dsp` actions. The
[configuration](../../modules/features/desktop/hyprland/config/hyprland.nix#L18-L19)
exposes the package's Lua stubs, while the
[generated-Lua check](../../modules/checks.nix#L754-L769) checks syntax rather than
proving that embedded legacy command strings are accepted by the compositor.

## Decision And Scope

Replace these two legacy command paths with native Lua dispatchers supported by
the package selected by the [locked inputs](../../flake.lock). Confirm argument
shapes from that version's stubs/implementation, not examples for another release.

Preserve the existing shortcuts, next-output movement, 80-pixel resize directions,
and repeating resize behavior. Do not rewrite unrelated bindings, change monitor
identities or workspace assignments, or add Noctalia-specific compositor logic.

## Acceptance Criteria

- [ ] Next-monitor movement uses a native dispatcher supported by the pinned package.
- [ ] All four resize directions use native actions with the existing step and repeat behavior.
- [ ] The affected bindings no longer spawn legacy `movewindow` or `resizeactive` commands.
- [ ] Offline checks cover dispatcher names/arguments as well as generated Lua syntax.
- [ ] Native movement/resize evidence is recorded, or explicitly awaits the approved desktop trial.

## Verification And Approval

Run formatting, evaluation, generated-Lua and affected desktop checks, then build
the Zaros closure after implementation. Stub-backed or mocked action assertions
can verify generated intent offline, but cannot prove real window behavior.
Physical shortcut and multi-monitor testing remains
[ISSUE-037](037-native-desktop-validation.md); no live reload, session launch,
activation, or monitor operation is authorized by this issue.

## Resolution

Replaced `hyprctl dispatch movewindow mon:+1` with `hl.dsp.window.move({ monitor = "+1" })` and the four `resizeactive` bindings with `hl.dsp.window.resize({ x, y, relative = true })` (same 80-pixel steps, still repeating). Accepted by the pinned 0.56.2 `Hyprland --verify-config`, which also rejects malformed arguments. `generated-lua` now fails if a legacy `movewindow`/`resizeactive` dispatch string reappears. Open: native movement/resize test under ISSUE-037.

[Back to backlog](README.md)
