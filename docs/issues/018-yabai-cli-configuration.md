# ISSUE-018: Align Yabai settings and signals with the pinned CLI

- Status: open
- Priority: P2
- Kind: Source-confirmed settings and signal compatibility defects
- Scope: Yabai CLI configuration, bar reservation, and application-exit signal
- Dependencies: none; native runtime verification is tracked in ISSUE-038

## Problem And Evidence

The [Yabai settings](../../modules/features/desktop/darwin/yabai.nix#L6-L34)
include `window_animation_frame_rate`, unsupported by the reviewed pin 7.1.25.
They also set `external_bar = "all:48"`, omitting the required bottom value
from the `all:<top>:<bottom>` form. These commands can be rejected even when
Nix evaluation succeeds; this is not proof that every later setting fails.

The [signals](../../modules/features/desktop/darwin/yabai.nix#L36-L40) use
`application_closed`, which is not a valid event; the exit event is
`application_terminated`. Existing `top_padding = 48` must also be considered
when correcting bar reservation, rather than blindly adding another 48 pixels.

## Decision And Scope

Recheck the current pin, remove or replace unsupported settings, supply valid
external-bar syntax, and use the supported application-termination event.
Define the intended total top inset with the bar and existing padding together.
Keep focus fallback policy and scripting-addition/security policy unchanged;
the SketchyBar focus bridge is separate [ISSUE-019](019-yabai-sketchybar-events.md).

## Acceptance Criteria

- [ ] Every emitted setting is supported by the pinned Yabai CLI.
- [ ] External-bar syntax includes top and bottom values without unintended double padding.
- [ ] Application-exit focus handling registers `application_terminated` successfully.
- [ ] Checks distinguish command acceptance from native layout and focus behavior.

## Verification And Approval

For an approved implementation, compare generated commands with pinned source
and exercise mocked command capture before formatting, evaluation, and a native
Apple-Silicon closure build. Live CLI configuration, signal registration,
window/layout changes, and service restarts require separate runtime approval
through [ISSUE-038](038-native-darwin-validation.md). Do not disable SIP or change
TCC/scripting-addition permissions to validate this issue without explicit approval.

## Resolution

Not resolved.

[Back to backlog](README.md)
