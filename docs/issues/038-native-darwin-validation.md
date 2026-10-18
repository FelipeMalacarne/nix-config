# ISSUE-038: Perform approved native MacBook validation

- Status: deferred
- Priority: P2
- Kind: Native build and runtime evidence gap; not a reproduced host outage
- Scope: Apple-Silicon MacBook closure and separately approved desktop smoke tests
- Dependencies: Coordinate ISSUE-016 through ISSUE-021 and ISSUE-043; explicit runtime approval

## Problem And Evidence

The [MacBook host](../../hosts/macbook/default.nix#L11-L25) targets
`aarch64-darwin` and selects Yabai, skhd, SketchyBar, SOPS, and Firefox.
The review established evaluation, not a native closure build or working session.
Linux evaluation or mocked commands cannot establish macOS framework, launchd,
TCC, window-management, native helper, or external-application behavior.

The [CI matrix](../../.github/workflows/check.yml#L9-L21) includes macOS, but
configured CI is not evidence of a successful run for the candidate revision.
[README](../../README.md#validation-and-deferred-work) and
[AGENTS.md](../../AGENTS.md#validation-and-deployment)
retain explicit deployment, native-runtime, and security/bootstrap approval gates.

## Decision And Scope

Schedule native build verification and runtime testing as distinct activities.
Assess fixes [016](016-darwin-firefox-profile.md), [017](017-skhd-shortcuts.md),
[018](018-yabai-cli-configuration.md), [019](019-yabai-sketchybar-events.md),
[020](020-sketchybar-runtime-dependencies.md), and [021](021-sketchybar-helper-lifecycle.md)
before claiming broad desktop readiness. Coordinate secret-dependent coverage with
[ISSUE-043](043-darwin-sops-bootstrap.md), without making unrelated tests depend on keys.
Record current security prerequisites; do not authorize disabling SIP or granting TCC.

## Acceptance Criteria

- [ ] Formatting, evaluation, relevant checks, and the native MacBook closure build are recorded.
- [ ] An owner-approved runtime matrix states prerequisites, recovery, and permitted actions.
- [ ] Approved checks cover shortcuts, Yabai layout/focus, bar events/helper, and Firefox profiles.
- [ ] External apps, secret-dependent limits, and security prerequisites are documented safely.
- [ ] Unexecuted checks remain explicit; build success alone is not called runtime validation.

## Verification And Approval

Use a native Apple-Silicon builder for `make build-darwin` when validating an
implementation; retain the revision and logs without secret values. Before runtime work, obtain
separate approval for activation, service restarts, input/window/audio actions,
and any TCC, SIP, or scripting-addition changes. Agree recovery before disruption.
This deferred entry authorizes no commands, permission changes, deployment, or tests.

## Resolution

Not resolved.

[Back to backlog](README.md)
