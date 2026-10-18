# ISSUE-015: Match Dolphin's terminal preference to the selected terminal

- Status: resolved
- Priority: P2
- Kind: source-confirmed missing command and desktop-entry selection
- Scope: Dolphin and shared desktop terminal preferences
- Dependencies: none

## Problem And Evidence

[Dolphin's kdeglobals](../../modules/features/programs/dolphin.nix) names
`alacritty` and `Alacritty.desktop`. The
[desktop profile](../../modules/profiles/desktop.nix) selects
[Ghostty](../../modules/features/programs/ghostty.nix), not Alacritty. Actions
that honor the KDE terminal preference can therefore target an absent program.

## Decision And Scope

Use the selected terminal and its installed desktop entry. For the current
Ghostty selection, verify `com.mitchellh.ghostty.desktop` rather than guessing
the entry's name. Reuse the existing desktop terminal policy where appropriate;
do not install an unwanted terminal simply to satisfy stale configuration.
The wrapper's package footprint is separate in
[ISSUE-031](031-dolphin-runtime-wrapper.md).

## Acceptance Criteria

- [ ] KDE's terminal command resolves to the selected, installed terminal.
- [ ] The configured terminal desktop entry exists in the built environment.
- [ ] Generated preferences contain no stale Alacritty requirement for Zaros.
- [ ] An isolated configuration regression covers the command and desktop ID.

## Verification And Approval

Inspect the generated kdeglobals and installed desktop entry, run affected
checks, and build Zaros. A GUI smoke test of Dolphin's terminal action requires
an approved desktop session; do not activate the configuration or launch GUI
applications into the current session as part of offline verification.

## Resolution

Already fixed: Dolphin takes `my.desktop.terminalCommand`/`terminalDesktopId`, falling back to Ghostty.

[Back to backlog](README.md)
