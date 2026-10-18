# Configuration Issue Backlog

This backlog turns the system review into independently assessable work. It
includes confirmed defects, conditional risks, optional improvements, and
previously deferred operational work. An issue is not permission to implement
every proposed solution or change a running machine.

Recheck the linked sources and current input versions before starting an issue.
Source-level findings do not establish that a symptom has occurred on a running
host. External backups, imperative installations, and runtime configuration can
change the impact and must be assessed rather than assumed.

## Using The Backlog

1. Pick one issue, read its evidence, and confirm that it still applies.
2. Resolve any usage or policy decisions and check dependencies and approval gates.
3. Change its status to `in-progress` and keep implementation within its scope.
4. Run the issue-specific verification and record results in its Resolution section.
5. Update the issue and this index together when resolving, deferring, or rejecting it.

Keep IDs stable. Do not delete resolved issues or reuse their numbers. Record
the chosen approach, relevant commit, checks performed, and remaining runtime
limits in the issue instead of treating a code change alone as proof of success.
An approved `wont-fix` decision should explain why the risk or tradeoff is accepted.

### Status

- `open`: actionable work, subject to the issue's explicit approval limits.
- `needs-decision`: usage, ownership, scope, or policy must be agreed first.
- `in-progress`: actively being evaluated or implemented.
- `blocked`: waiting on a dependency or required approval.
- `deferred`: operational or policy work intentionally postponed; evaluation is allowed.
- `resolved`: acceptance criteria met, with evidence and any accepted limits recorded.
- `wont-fix`: explicitly reviewed and rejected or accepted as a tradeoff.

### Priority And Evidence

- `P1`: security, availability, recovery, or a blocked validation path.
- `P2`: functional correctness, reliability, or important maintenance.
- `P3`: optional simplification, storage optimization, or workflow cleanup.
- Each issue's Kind distinguishes reproduced failures, source-confirmed defects,
  conditional risks, decisions, and unverified runtime behavior.

Priority is a triage aid, not a claim that every P1 is a current outage or an
authorization to execute high-risk work.

## Issues

| ID | Issue | Priority | Status |
|---|---|---|---|
| ISSUE-001 | [Clean flake sources for formatting and CI](001-clean-flake-sources.md) | P1 | in-progress |
| ISSUE-002 | [Align desktop checks and documentation with host selections](002-desktop-selection-checks.md) | P1 | resolved |
| ISSUE-003 | [Cover the plain Hyprland login path with locking](003-plain-hyprland-locking.md) | P1 | open |
| ISSUE-004 | [Decide whether to retain i3 and provide locking if retained](004-i3-selection-and-locking.md) | P1 | needs-decision |
| ISSUE-005 | [Decouple LAN DNS from Tailscale address availability](005-adguard-dns-availability.md) | P1 | open |
| ISSUE-006 | [Replace legacy dispatch commands in Hyprland Lua](006-hyprland-lua-dispatch.md) | P2 | open |
| ISSUE-007 | [Align Hyprland's locale with generated locales](007-hyprland-locale.md) | P2 | resolved |
| ISSUE-008 | [Use Noctalia's lock-ready suspend action](008-noctalia-suspend-locking.md) | P2 | in-progress |
| ISSUE-009 | [Decide and provision external-monitor DDC controls](009-noctalia-ddc-controls.md) | P2 | needs-decision |
| ISSUE-010 | [Make the Noctalia volume action executable](010-noctalia-volume-action.md) | P2 | open |
| ISSUE-011 | [Supply KUBECONFIG to Hermes background services](011-hermes-kubeconfig.md) | P2 | open |
| ISSUE-012 | [Choose a consistent SOPS editing and key-access workflow](012-sops-editing-permissions.md) | P2 | needs-decision |
| ISSUE-013 | [Make base's secret-backed SSH dependency explicit](013-base-sops-dependency.md) | P2 | resolved |
| ISSUE-014 | [Align Neovim LSP names and packaged servers](014-neovim-lsp-configuration.md) | P2 | resolved |
| ISSUE-015 | [Align Dolphin's terminal preference with Ghostty](015-dolphin-terminal.md) | P2 | resolved |
| ISSUE-016 | [Use the native Firefox profile location on Darwin](016-darwin-firefox-profile.md) | P2 | resolved |
| ISSUE-017 | [Remove conflicting skhd shortcuts](017-skhd-shortcuts.md) | P2 | open |
| ISSUE-018 | [Align Yabai settings and signals with the pinned CLI](018-yabai-cli-configuration.md) | P2 | open |
| ISSUE-019 | [Connect Yabai focus events to SketchyBar](019-yabai-sketchybar-events.md) | P2 | open |
| ISSUE-020 | [Declare SketchyBar plugin runtime dependencies](020-sketchybar-runtime-dependencies.md) | P2 | open |
| ISSUE-021 | [Build and manage the SketchyBar helper declaratively](021-sketchybar-helper-lifecycle.md) | P2 | open |
| ISSUE-022 | [Make Wake-on-LAN setup resilient to device lifecycle](022-wake-on-lan-lifecycle.md) | P2 | open |
| ISSUE-023 | [Decide server backup coverage and consistency](023-server-backup-coverage.md) | P1 | needs-decision |
| ISSUE-024 | [Decide backup coverage for mutable Hermes state](024-hermes-state-backups.md) | P2 | needs-decision |
| ISSUE-025 | [Add the intended Dark Souls III save backups](025-dark-souls-backups.md) | P2 | needs-decision |
| ISSUE-026 | [Verify restore procedures and independent recovery credentials](026-restore-verification.md) | P1 | deferred |
| ISSUE-027 | [Review AdGuard administrative authentication and access](027-adguard-admin-access.md) | P1 | deferred |
| ISSUE-028 | [Bound server media and download capacity](028-server-data-capacity.md) | P2 | needs-decision |
| ISSUE-029 | [Audit heavyweight application and service selections](029-heavyweight-feature-audit.md) | P3 | needs-decision |
| ISSUE-030 | [Consider a lean base editor for headless hosts](030-lean-base-neovim.md) | P3 | resolved |
| ISSUE-031 | [Simplify Dolphin's runtime wrapper](031-dolphin-runtime-wrapper.md) | P3 | open |
| ISSUE-032 | [Remove or scope the stale Electron security exception](032-electron-security-exception.md) | P2 | resolved |
| ISSUE-033 | [Audit unused flake inputs and the NVF cache](033-unused-inputs-and-cache.md) | P3 | resolved |
| ISSUE-034 | [Correct the installed Nix skill's architecture guidance](034-nix-skill-guidance.md) | P2 | wont-fix |
| ISSUE-035 | [Evaluate a controlled core dependency update](035-core-dependency-update.md) | P2 | needs-decision |
| ISSUE-036 | [Upgrade CI actions and their Node runtime](036-ci-action-upgrades.md) | P2 | resolved |
| ISSUE-037 | [Perform an approved native desktop smoke test](037-native-desktop-validation.md) | P1 | deferred |
| ISSUE-038 | [Perform approved native MacBook validation](038-native-darwin-validation.md) | P2 | deferred |
| ISSUE-039 | [Review password-hash ownership and recovery policy](039-password-hash-policy.md) | P1 | deferred |
| ISSUE-040 | [Review SSH and firewall policy without losing access](040-ssh-firewall-policy.md) | P1 | deferred |
| ISSUE-041 | [Review broad Tailscale interface trust](041-tailscale-trust-policy.md) | P2 | deferred |
| ISSUE-042 | [Review Disko device-selection safety](042-disko-device-safety.md) | P1 | deferred |
| ISSUE-043 | [Define the Darwin SOPS bootstrap procedure](043-darwin-sops-bootstrap.md) | P2 | deferred |
| ISSUE-044 | [Complete or retire the dormant OpenClaw token integration](044-openclaw-token-provider.md) | P2 | resolved |

## Suggested Sequence

1. Restore trustworthy validation with ISSUE-001 and ISSUE-002 before broad updates.
2. Evaluate locking coverage and DNS availability in ISSUE-003 through ISSUE-005;
   assess the existing administrative-access risk in ISSUE-027 separately.
3. Fix independent command, environment, profile, and lifecycle defects in small changes.
4. Decide valuable data and backup coverage before pruning mutable state or changing storage.
5. Evaluate package selection and dependency upgrades with a green baseline and measured results.
6. Schedule native validation, restore drills, and deferred policy changes only after approval.

Dependencies identify coordination needs, not permission to combine unrelated
issues into one refactor. In particular, ISSUE-004 may be resolved by removing
an unused session rather than implementing an unwanted desktop stack.
Evaluation can start before related issues are closed. An implementation may
wait for an approved runtime check while that check proceeds against the built
candidate; record that state instead of introducing a circular closure gate.

## Verification And Safety

For configuration changes, follow [AGENTS.md](../../AGENTS.md): finish formatting,
evaluation, affected checks, and affected-closure builds before claiming readiness.
Use `make fmt-check`, `make eval-check`, relevant `nix build` check outputs, and
`make build-all` or a targeted host build as appropriate. Darwin builds need a
native Apple-Silicon builder. Documentation-only changes need link, consistency,
and formatting checks, not unrelated system rebuilds.

Activation, rollback, remote deployment, reboot/logout, service restarts, physical
session tests, recovery operations, credential changes, firewall/trust changes,
and disk operations are not authorized by this backlog. Existing deferred
boundaries remain in force. Desktop trials require a known-good generation and
TTY recovery; do not restart the live greeter as a shortcut.

Tests that inspect generated files or mocked services do not verify physical
login, locking, graphics, networking, wake, or restore behavior. If required
runtime evidence is unavailable, leave that acceptance criterion open and record
the limitation instead of marking the issue resolved.

## Baseline And Completed Work

- Weekly garbage collection with `--delete-older-than 7d` is already configured
  in [shared NixOS core](../../modules/features/system/core/config/nixos.nix).
  It is not an outstanding implementation task and is not configured for Darwin.
  No activation or manual collection was authorized by the review.
- The review built all three NixOS closures and 20 additional Linux checks
  independently. Full evaluation stopped at the desktop-default mismatch in
  ISSUE-002. The separate clean-checkout CI failure is tracked in ISSUE-001.
- Darwin evaluated, but its native closure build and runtime were not established
  by the local review. See ISSUE-038.
- Observed logical closure sizes were approximately 44.5 GiB for Zaros, 5.2 GiB
  for Saradomin, and 3.9 GiB for its VM. These are historical review measurements,
  not physical disk usage or guaranteed cleanup savings; remeasure for ISSUE-029.
- The pre-existing [Dark Souls III backup note](../todo.md) is retained and tracked
  by ISSUE-025. No personal save paths or credential values need to be duplicated here.
