# ISSUE-020: Declare SketchyBar plugin runtime dependencies

- Status: open
- Priority: P2
- Kind: Source-confirmed undeclared service dependencies; runtime impact conditional
- Scope: SketchyBar plugin executables, service environment, and optional widgets
- Dependencies: Widget selection and external authentication prerequisites

## Problem And Evidence

The [SketchyBar service](../../modules/features/desktop/darwin/sketchybar.nix#L45-L54)
sets no `extraPackages`. Its launchd environment must not be assumed to inherit
an interactive shell's PATH. Plugins invoke `jq`,
[GitHub CLI](../../assets/sketchybar/plugins/github.sh#L3-L8), and
[SwitchAudioSource](../../assets/sketchybar/plugins/volume_click.sh#L22-L39).
The corresponding `switchaudio-osx` package is not selected in this configuration.

The [bar config](../../assets/sketchybar/sketchybarrc#L76-L84) also loads the
[brew widget](../../assets/sketchybar/plugins/brew.sh#L1-L5), which calls `brew`.
Imperative installations may mask these gaps; no running-widget outage is proven.
GitHub authentication is a separate prerequisite, not supplied by installing `gh`.

## Decision And Scope

Declare selected plugin tools through the supported service environment or
explicit packaged executable paths. Include `jq`, `gh`, and `switchaudio-osx`
where their widgets remain enabled, and audit other selected plugin commands.
Guard or disable the optional brew widget when Homebrew is undeclared; do not
silently install Homebrew or read credentials to make a widget appear functional.
Keep helper packaging separate in [ISSUE-021](021-sketchybar-helper-lifecycle.md).

## Acceptance Criteria

- [ ] Enabled plugins find their declared tools in a minimal service environment.
- [ ] Audio device selection has a declared `SwitchAudioSource` provider if retained.
- [ ] Optional Homebrew behavior is safe when `brew` is absent.
- [ ] Authentication requirements and remaining external prerequisites are documented.

## Verification And Approval

For approved implementation, inspect generated launchd PATH/wrappers and test
scripts with minimal environments and mocked commands, without contacting APIs
or changing audio devices. Run formatting, evaluation, and a native Apple-Silicon
closure build. Native widget interaction and service restarts need separate
[ISSUE-038](038-native-darwin-validation.md) approval; never print tokens or secrets.

## Resolution

Not resolved.

[Back to backlog](README.md)
