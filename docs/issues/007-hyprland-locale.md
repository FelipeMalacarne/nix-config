# ISSUE-007: Align Hyprland's locale with generated locales

- Status: resolved
- Priority: P2
- Kind: source-confirmed mismatch supported by prior Nix evaluation
- Scope: Hyprland LC_CTYPE and the affected host's generated locale set
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for trustworthy validation

## Problem And Evidence

[Hyprland's Lua](../../modules/features/desktop/hyprland/config/hyprland.lua#L24-L27)
exports `LC_CTYPE=pt_BR.UTF-8`. The
[shared NixOS core](../../modules/features/system/core/config/nixos.nix#L17)
sets `i18n.defaultLocale` to `en_US.UTF-8`; review evaluation found only
`C.UTF-8` and `en_US.UTF-8` in the generated locale set.

The compositor therefore advertises a locale that the evaluated host does not
generate. Applications that inherit it can fail locale initialization or fall
back unexpectedly. This is not evidence that a particular application failure
or compose-key regression was reproduced on the running desktop.

## Decision And Scope

Either generate the intended Brazilian Portuguese locale for the affected host,
or remove/replace the compositor-only override with an available locale. Confirm
the intended character/compose behavior before choosing; do not change every
host's language or regional defaults just to satisfy this binding.

Keep keyboard layout, variant, compose-file policy, monitor topology, and shell
provider selection unchanged unless a separately approved requirement demands it.
Assert the relationship between exported locale and generated locales so that
syntactically valid Lua cannot silently reintroduce this mismatch.

## Acceptance Criteria

- [ ] The intended LC_CTYPE behavior and chosen locale policy are documented.
- [ ] Every explicit Hyprland locale override is available in the affected host's locale set.
- [ ] Evaluation checks cover locale availability using the generated Lua/environment policy.
- [ ] Unrelated hosts, keyboard settings, and regional defaults remain unchanged.
- [ ] Approved runtime checks confirm locale/compose behavior, or remain explicitly outstanding.

## Verification And Approval

After implementation, run formatting, evaluation, generated-Lua checks, and the
affected Zaros closure build. Inspect generated locale data and environment
offline; these checks do not establish what an existing graphical process has
inherited. Fresh-session application and compose checks belong to
[ISSUE-037](037-native-desktop-validation.md). No logout, reload, activation, or
other running-session modification is authorized here.

## Resolution

Added `i18n.extraLocales = [ "pt_BR.UTF-8/UTF-8" ]` in the Hyprland NixOS module so the exported `LC_CTYPE` exists. Verified by evaluation and `nix flake check`; no native session test was run.

[Back to backlog](README.md)
