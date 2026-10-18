# ISSUE-002: Align checks with the selected desktop default

- Status: resolved
- Priority: P1
- Kind: reproduced evaluation failure
- Scope: desktop checks and host-selection documentation
- Dependencies: none; coordinate source-check results with [ISSUE-001](001-clean-flake-sources.md)

## Problem And Evidence

[Zaros selects Hyprland](../../hosts/zaros/desktop.nix), while the
[desktop-session check](../../modules/features/desktop/desktop/config/test_sessions.nix)
asserts that its default and native display-manager identifier are `umbriel`.
`make eval-check` failed at this assertion during review. The
[README](../../README.md) and [agent instructions](../../AGENTS.md) also describe
the older default.

## Decision And Scope

Preserve the user's Hyprland selection. Update the deliberate host expectations
and consider testing the default-to-native-ID invariant separately from personal
preferences. Keep explicit fixtures for Umbriel, managed Hyprland, and any
retained i3 fallback. Coordinate i3 expectations with
[ISSUE-004](004-i3-selection-and-locking.md), without removing it in this issue.

## Acceptance Criteria

- [ ] The selected host default maps to `hyprland-uwsm` and is forwarded to Home Manager.
- [ ] Evaluation no longer fails solely because Zaros defaults to Hyprland.
- [ ] Supported and rejected composition variants remain covered by checks.
- [ ] README and AGENTS describe the actual selection without changing monitor facts.

## Verification And Approval

Run `make fmt-check`, `make eval-check`, the desktop-session, greeter-session,
and native configuration checks, and the affected Zaros closure build. Do not
change the user's default back to satisfy the old test or launch a physical
session. Runtime desktop validation remains
[ISSUE-037](037-native-desktop-validation.md) and requires approval.

## Resolution

Already fixed: `test_sessions.nix` asserts Zaros defaults to `hyprland` mapped to `hyprland-uwsm`, and `README.md` documents Hyprland as the default. Verified by source review; `nix flake check` evaluates all hosts.

[Back to backlog](README.md)
