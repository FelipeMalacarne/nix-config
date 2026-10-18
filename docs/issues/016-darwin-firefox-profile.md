# ISSUE-016: Use the native Firefox profile location on Darwin

- Status: resolved
- Priority: P2
- Kind: Source-confirmed cross-platform profile-path defect
- Scope: Firefox Home Manager profile location on Darwin and Linux
- Dependencies: none; native runtime verification is tracked in ISSUE-038

## Problem And Evidence

The [Firefox feature](../../modules/features/programs/firefox.nix#L53-L66)
sets `configPath = ".mozilla/firefox"` unconditionally. That is the Linux
location; native Firefox on Darwin uses `Library/Application Support/Firefox`.
The [MacBook host](../../hosts/macbook/default.nix#L76-L85) selects this feature,
so generated profile settings can miss the native application's profile tree.

The Darwin `package = null` is intentional: Firefox itself is an external
installation prerequisite. This finding does not establish that Firefox is
absent, that a running profile is broken, or that user data has been lost.

## Decision And Scope

Use the platform-appropriate profile root, preferably the upstream module
default if it provides both paths. Preserve the Linux location, profile name,
extensions, Stylix integration, and intentional external Darwin installation.
Assess existing profile conflicts before any approved activation; do not move,
overwrite, or delete browser profiles as an incidental configuration fix.

## Acceptance Criteria

- [ ] Darwin generates the profile under `Library/Application Support/Firefox`.
- [ ] Linux retains `.mozilla/firefox` and existing profile settings.
- [ ] Darwin's external Firefox installation prerequisite remains explicit.
- [ ] Existing-profile handling and any deferred native verification are recorded.

## Verification And Approval

For a separately approved implementation, inspect generated Home Manager paths
for both platforms, run formatting and evaluation checks, and build the affected
closures, using a native Apple-Silicon builder for Darwin. Follow
[ISSUE-038](038-native-darwin-validation.md) for approved native profile checks.
This backlog entry authorizes no build, activation, browser launch, profile
migration, or modification of personal browser data.

## Resolution

Already fixed: Firefox `configPath` is Linux-only and the `firefox-platform` check asserts the Darwin location.

[Back to backlog](README.md)
