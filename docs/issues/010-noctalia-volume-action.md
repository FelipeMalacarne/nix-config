# ISSUE-010: Make the Noctalia volume action executable

- Status: in-progress
- Priority: P2
- Kind: source-confirmed undeclared executable dependency
- Scope: Noctalia volume widget's middle-click action
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for trustworthy validation

## Problem And Evidence

The [volume action](../../modules/features/desktop/noctalia/config/settings.toml#L320-L324)
sets middle-click to `exec pwvucontrol || pavucontrol`. Neither executable is
declared by the [Noctalia provider](../../modules/features/desktop/noctalia/noctalia.nix#L84-L92)
or elsewhere in the reviewed repository configuration.

The action therefore depends on undeclared programs in the graphical session's
environment. An imperative installation might mask the gap; the review did not
establish that a user click failed on the running desktop. Native TOML/schema
validation does not establish that an external action's command can execute.

## Decision And Scope

Prefer Noctalia's built-in Audio panel if it provides the wanted controls, or
select one mixer and declare its executable through the provider. Verify the
pinned shell's action syntax and command execution semantics rather than relying
on an unchecked shell fallback string.

Keep the change local to the volume action and its selected dependency. Do not
install both tools as a substitute for choosing an action, or alter shared audio
policy or compositor bindings. Account for [saved GUI overrides](../../README.md#noctalia-ui-workflow)
without editing or resetting live user state as part of an offline fix.

## Acceptance Criteria

- [ ] Middle-click has one intentional built-in or external mixer action.
- [ ] Any external executable is declared and resolvable in the shell's execution context.
- [ ] Offline checks validate the native action syntax and external dependency, if any.
- [ ] The unused fallback and any unnecessary dependencies are absent; saved overrides are considered.
- [ ] Approved UI testing confirms the intended panel/tool opens, or remains outstanding.

## Verification And Approval

After implementation, run formatting, evaluation, native Noctalia configuration
and export checks, then build the affected Zaros closure. Inspect the generated
action and dependency paths offline; schema success alone is insufficient to
prove a click works. Physical UI testing belongs to
[ISSUE-037](037-native-desktop-validation.md). Do not launch a mixer, change audio
devices/volume, reload the shell, or activate a configuration without approval.

## Resolution

Chose the no-override option: removed `[widget.volume.actions].middle` so the widget uses Noctalia's default, with no external mixer to declare. `noctalia config validate` does not check action strings, so no built-in panel id was introduced. Saved GUI overrides in the live state are untouched. Open: confirm the default behavior in the approved UI test (ISSUE-037).

[Back to backlog](README.md)
