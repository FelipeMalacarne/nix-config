# ISSUE-004: Decide whether to retain i3 and provide locking if retained

- Status: needs-decision
- Priority: P1
- Kind: session-selection decision with a source-confirmed locking gap
- Scope: Zaros's i3 selection and any retained X11 fallback's locking
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for validation and selection expectations

## Problem And Evidence

[Zaros selects i3](../../hosts/zaros/desktop.nix#L7-L11), although the user reports
that it is unused. The [i3 feature](../../modules/features/desktop/i3.nix)
declares neither a lock binding nor an X11 locker with idle/sleep integration.
Wayland shell locking does not supply that missing X11 protection.

The [desktop checks](../../modules/features/desktop/desktop/config/test_sessions.nix#L229-L237)
correctly exclude Wayland shells and idle services from i3-only configurations.
The [greeter](../../modules/features/desktop/noctalia-greeter.nix#L51-L62)
nevertheless exposes the selected X11 session through its dedicated wrapper.
This establishes a configuration gap, not a reproduced unlocked-resume incident.

## Decision And Scope

Ask whether an i3 fallback is wanted. If not, remove it from Zaros's selected
sessions and update affected expectations and documentation. This is a host
selection decision, not permission to remove reusable i3 capabilities from all
profiles or discard intentional coverage of supported variants.

If retained, declare an appropriate X11 locker, an explicit lock binding, and
session-scoped idle/pre-sleep integration with safe lock readiness. Keep X11
independent of Noctalia's Wayland lock path. Preserve existing XRandR topology,
session wrapping, and provider-neutral compositor boundaries.

## Acceptance Criteria

- [ ] The user-approved retain/remove decision and its scope are recorded.
- [ ] Host selections and advertised login entries agree with that decision.
- [ ] If retained, i3 has a declared locker, lock binding, idle policy, and safe sleep integration.
- [ ] Affected desktop/greeter fixtures and README/AGENTS match; unrelated capabilities remain intact.
- [ ] A retained fallback has approved native locking evidence; removal instead has discovery evidence that i3 is no longer offered.

## Verification And Approval

After the decision and implementation, run formatting, evaluation, affected
desktop/greeter checks, and the Zaros closure build. Offline tests should cover
both the chosen selection and any intentionally retained capability fixtures.
Native X11 login, authentication, idle, and sleep tests require approval under
[ISSUE-037](037-native-desktop-validation.md). Do not log out, restart the greeter,
activate a configuration, or exercise a physical session to settle this decision.

## Resolution

Not resolved.

[Back to backlog](README.md)
