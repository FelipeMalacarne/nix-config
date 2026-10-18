# ISSUE-029: Evaluate heavyweight packages and services by actual usage

- Status: needs-decision
- Priority: P3
- Kind: optional package-selection and storage assessment
- Scope: Zaros applications, background services, and mutable application data
- Dependencies: session removal is tracked in [ISSUE-004](004-i3-selection-and-locking.md)

## Problem And Evidence

[Zaros](../../hosts/zaros/default.nix) selects gaming launchers, office tools,
Ollama, recording, virtualization, Docker, and Flatpak. The review measured a
logical system closure of about 44.5 GiB, with large entries for OBS's browser
engine, Bolt Launcher, LibreOffice, Ollama, and QEMU. Size does not establish
that any of these selections is unnecessary.

## Decision And Scope

Inventory actual use before removing features. Consider the selected
[recording](../../modules/features/applications/recording.nix),
[office](../../modules/features/programs/office.nix), and
[Ollama](../../modules/features/services/ollama.nix) capabilities independently.
Keep GPU workloads on Zaros; do not move them to Saradomin. Chromium policy
enablement is not proof that another browser is installed. Identical package
references share store paths and are not duplicate copies.

## Acceptance Criteria

- [ ] The user has classified candidate features as retained, removed, or undecided.
- [ ] Before/after logical closures and exclusive savings are measured rather than summed from shared dependencies.
- [ ] Required GPU, recording, session, and development capabilities remain covered.
- [ ] Mutable data and old-generation retention are distinguished from installed closure size.

## Verification And Approval

Use read-only closure queries and inspect selected modules. Build each proposed
configuration before deployment and keep changes small enough to assess alone.
Weekly seven-day Nix GC is already configured in core, not an unimplemented task.
Do not run GC, delete generations, prune containers/volumes, remove game files or
models, or activate service removals without explicit approval.

## Resolution

Not resolved.

[Back to backlog](README.md)
