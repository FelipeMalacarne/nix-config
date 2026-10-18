# ISSUE-009: Decide and provision external-monitor DDC controls

- Status: needs-decision
- Priority: P2
- Kind: source-confirmed dependency gap with hardware/access policy undecided
- Scope: Noctalia DDC brightness controls and deliberately scoped host I2C access
- Dependencies: [ISSUE-001](001-clean-flake-sources.md) and [ISSUE-002](002-desktop-selection-checks.md) for trustworthy validation

## Problem And Evidence

The [brightness settings](../../modules/features/desktop/noctalia/config/settings.toml#L67-L68)
enable `ddcutil`, but the
[Noctalia feature's packages](../../modules/features/desktop/noctalia/noctalia.nix#L84-L92)
do not declare that executable. Review found no repository declaration supplying
it or establishing the intended monitor-control access policy.

Enabling a UI setting is not proof that the required executable, I2C devices,
permissions, or monitor support are present. An imperative installation could
change current behavior; no DDC hardware probe or brightness operation established
the runtime impact. Package availability alone would not prove safe access.

## Decision And Scope

Decide whether external-monitor DDC controls are wanted. If not, disable the
unsupported setting. If retained, declare `ddcutil` and deliberately provision
the required kernel/device access on the intended host, using narrowly scoped
permissions rather than broad device modes or unexplained privileged commands.

Keep hardware facts and access policy with the host/system integration, and
Noctalia's UI dependencies with its provider. Preserve [monitor identities and
topology](../../hosts/zaros/desktop.nix); do not substitute connector names for
serial-bearing Wayland identities or assume a disconnected display was tested.

## Acceptance Criteria

- [ ] The user-approved enable/disable decision and affected host scope are recorded.
- [ ] Enabled DDC controls have a declared executable, or the unsupported setting is disabled.
- [ ] Any retained I2C access policy is reviewed, least-privilege, and scoped to intended users/devices.
- [ ] Offline checks cover settings, executable availability, and any declarative access policy.
- [ ] Approved hardware evidence records supported displays and limits, or remains outstanding.

## Verification And Approval

After implementation, run formatting, evaluation, Noctalia checks, and the
affected Zaros closure build. Inspect package and permission declarations offline;
do not probe I2C buses, load modules, change groups/permissions, or adjust brightness.
Hardware validation requires separate explicit approval under
[ISSUE-037](037-native-desktop-validation.md), including approval for any DDC probe
or write. This issue does not authorize activation or privilege changes.

## Resolution

Not resolved.

[Back to backlog](README.md)
