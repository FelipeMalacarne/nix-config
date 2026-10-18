# ISSUE-031: Reduce Dolphin's runtime wrapper to necessary dependencies

- Status: open
- Priority: P3
- Kind: source-confirmed runtime footprint and startup-work concern
- Scope: Dolphin overlay, XDG menu data, and service-cache initialization
- Dependencies: none; terminal preferences are separate in [ISSUE-015](015-dolphin-terminal.md)

## Problem And Evidence

The [Dolphin overlay](../../modules/features/programs/dolphin.nix) joins both the
runtime and `.dev` output into the installed package. Its wrapper also references
Qt5's internal KService menu data and runs `kbuildsycoca6 --noincremental` on every
launch. This retains development/legacy dependencies and repeats cache work.
The review did not prove that removing the workaround leaves menu discovery intact.

## Decision And Scope

Find the original application-discovery requirement before simplifying. Remove
the SDK output if it has no runtime consumer, and supply needed menu data through
the appropriate current XDG/KDE integration. Avoid replacing a working workaround
with an untested assumption or changing unrelated KDE application selections.

## Acceptance Criteria

- [ ] The installed wrapper contains only justified runtime outputs.
- [ ] Legacy Qt5 menu-data dependencies are removed or their necessity is documented.
- [ ] Full KDE service-cache rebuilds are not performed on every launch without a demonstrated requirement.
- [ ] File handlers, application menus, and terminal actions retain intended behavior.

## Verification And Approval

Compare wrapper references and closures before/after, inspect generated XDG
configuration, run affected checks, and build Zaros. Use isolated cache/home
fixtures for startup tests where possible. Native Dolphin/menu verification is
part of approved desktop testing, not permission to mutate the current session's
service cache or activate the new package.

## Resolution

Not resolved.

[Back to backlog](README.md)
