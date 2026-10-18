# ISSUE-019: Connect Yabai focus events to SketchyBar

- Status: open
- Priority: P2
- Kind: Source-confirmed missing custom-event producer
- Scope: Yabai window-focus signal bridge and SketchyBar state refresh
- Dependencies: Coordinate with ISSUE-018 and ISSUE-020; runtime checks in ISSUE-038

## Problem And Evidence

The [Yabai item](../../assets/sketchybar/items/yabai.sh#L11-L15) registers and
subscribes to the custom SketchyBar event `window_focus`. Its
[plugin](../../assets/sketchybar/plugins/yabai.sh#L46-L51) refreshes window state
on that event or a mouse click, rather than on every generic bar update.

The [Yabai module](../../modules/features/desktop/darwin/yabai.nix#L36-L40)
has no `window_focused` signal forwarding to `sketchybar --trigger window_focus`.
Declaring a custom event does not produce it. Normal focus changes therefore
lack the configured refresh path; this is not a native observation of stale UI.

## Decision And Scope

Add an explicit producer for the existing custom event, or consistently adopt
a supported equivalent event path. Keep event registration and subscription
aligned, use executable paths available to the service, and make repeated
configuration loads avoid accumulating duplicate signal handlers.
Coordinate CLI compatibility with [ISSUE-018](018-yabai-cli-configuration.md)
and service dependencies with [ISSUE-020](020-sketchybar-runtime-dependencies.md).

## Acceptance Criteria

- [ ] A supported Yabai window-focus event reaches the matching SketchyBar subscriber.
- [ ] Repeated configuration loading leaves one intended bridge, not duplicate handlers.
- [ ] Mocked focus events demonstrate trigger routing and plugin refresh behavior.
- [ ] Missing-bar or no-focused-window behavior is intentional and documented.

## Verification And Approval

For an approved implementation, capture generated signal commands and exercise
the producer/consumer contract with mocked Yabai, SketchyBar, and window data.
Run formatting, evaluation, and a native Apple-Silicon affected-closure build.
Only separately approved [ISSUE-038](038-native-darwin-validation.md) testing may
register live signals, reload services, or switch real window focus. Do not
claim mocks or a Linux build establish native event delivery.

## Resolution

Not resolved.

[Back to backlog](README.md)
