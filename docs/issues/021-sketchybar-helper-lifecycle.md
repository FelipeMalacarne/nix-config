# ISSUE-021: Build and manage the SketchyBar helper declaratively

- Status: open
- Priority: P2
- Kind: Source-confirmed immutable-path build and process-ownership defects
- Scope: SketchyBar native helper packaging, startup, shutdown, and diagnostics
- Dependencies: Native Apple-Silicon builder; approved runtime checks in ISSUE-038

## Problem And Evidence

Home Manager [links the helper directory](../../modules/features/desktop/darwin/sketchybar.nix#L35-L42)
into the immutable Nix store. The [startup script](../../assets/sketchybar/sketchybarrc#L12-L16)
then runs `make` there. The [makefile](../../assets/sketchybar/helper/makefile)
writes `helper` beside its sources, so startup cannot rebuild that output.
A committed binary currently masks this design rather than proving rebuildability.

Startup also runs broad `killall helper` and discards the new process's output.
That can target unrelated same-named processes and hide failures. The
[helper source](../../assets/sketchybar/helper/helper.c#L21-L30) runs an event
server; its lifetime and single-instance ownership need explicit management.

## Decision And Scope

Build the helper from source in a Darwin derivation and reference its installed
executable, without relying on the committed binary or runtime compilation.
Choose scoped process ownership tied to the bar or a dedicated user service,
with deliberate reload, shutdown, and diagnostic behavior. Preserve its IPC
contract and CPU widget integration; avoid unrelated plugin or system-agent changes.

## Acceptance Criteria

- [ ] A native derivation builds the helper from source without the committed binary.
- [ ] Bar startup writes no build output into Home Manager's store-backed links.
- [ ] Reload and shutdown manage only the owned helper, without `killall helper`.
- [ ] Helper startup failures and useful diagnostics remain observable.
- [ ] Approved lifecycle checks establish one owned helper without affecting others.

## Verification And Approval

For approved implementation, inspect generated executable paths and test lifecycle
logic with mocked processes before formatting, evaluation, and a native
Apple-Silicon closure build. Actual helper launch, termination, bar reload,
and IPC checks need separate [ISSUE-038](038-native-darwin-validation.md) approval.
Do not kill processes or modify the Nix store while documenting or testing statically.

## Resolution

Not resolved.

[Back to backlog](README.md)
