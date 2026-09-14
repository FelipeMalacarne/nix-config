# Hermes Agent

Zaros selects `my.hermes-agent.enable = true`. The optional-feature catalog
exposes the option on NixOS, disabled by default. The implementation lives in
`modules/features/programs/hermes-agent.nix`, not in the general programming
package list.

## Ownership

- Home Manager imports upstream `homeManagerModules.default` for both
  `programs.hermes-agent` and `services.hermes-agent`.
- The CLI, desktop launcher and dashboard use the account's existing `~/.hermes`.
- `hermes-backend.service` is a **user** service. NixOS enables account linger so
  it continues after logout. No system-wide Hermes account/service is created.
- The dashboard listens on `http://127.0.0.1:9119`. No firewall ports are opened.
- The messaging gateway is disabled. Enable the Home Manager option
  `services.hermes-agent.gateway.enable` separately if needed.

The desktop connects to the managed dashboard backend using
`services.hermes-agent.backend.sessionTokenFile`. Activation generates
`~/.hermes/.backend-session-token` locally with mode `0600`, before Home Manager
reloads user services. Creation is atomic and later rebuilds keep the same token.
Both launchers read it at runtime; its value never enters the Nix store or the
repository. Empty, symlinked, or non-regular token files fail setup rather than
being silently replaced. An explicitly configured alternative token path (for
example SOPS) is caller-managed; this feature does not create or change it.

## Configuration and credentials

The feature preserves the selected model, `openai/gpt-5.6-sol`. Home Manager
merges declared settings into the writable config on activation; undeclared
settings are preserved. The upstream managed-mode marker makes some interactive
configuration commands refuse changes, so change Nix-managed settings here and
rebuild.

The declared baseline enables memory and user-profile learning, secret redaction,
verification-on-stop and filesystem checkpoints. `approvals.mode = "manual"`
requires human approval for flagged commands rather than smart auto-approval.
`skills.write_approval = true` stages agent skill changes for review; use
`/skills pending` and `/skills diff <id>` before approving a proposed lesson.
These safeguards are not a sandbox, a backup, or a substitute for Git and Nix
generations. Automatic deployment and scheduled jobs are not enabled.

The backend receives Nix, nixfmt, Make, Git, jq, ripgrep, fd, uv, curl and (on
Linux) systemctl through `services.hermes-agent.extraPackages`. Project-specific
dependencies still belong in project dev shells. Do not install Python packages
into the immutable Hermes runtime or system Python.

## Writable learning

Activation seeds `~/.hermes/skills/nix-system-workflow/SKILL.md` as an ordinary,
private writable file, only when absent. The seed is versioned under
`modules/features/programs/hermes-agent/config/nix-system-workflow/SKILL.md`.
Existing skills, memories and local improvements are not overwritten on rebuild.
Updates to the seed must be reviewed and merged deliberately into an existing
runtime copy. This also means a previously archived or intentionally removed
seed will be restored if it is absent at the next activation.

Select the repository root as the desktop project so its `AGENTS.md` supplies
machine-specific rules. The skill supplies reusable Nix workflows across
projects; memory is for small durable facts, not task logs. Keep learning and
OAuth state writable under the active Hermes home, not declaratively installed
via `hermesHomeFiles`.

`environment`, `environmentFiles` and `authFile` are intentionally unset. Existing
`.env` and OAuth credentials are not replaced by activation. If credentials are
later moved to SOPS, use runtime string paths. Upstream reconstructs `.env` when
`environment` or `environmentFiles` is set; do not use `~/.hermes/.env` itself as
an input to that operation.

## Dependency pin

Hermes keeps its own nixpkgs input. Its desktop package has a fixed Electron
header checksum but selects the header URL using `electron.version`. Making
Hermes follow the system nixpkgs can therefore break the desktop build.

When changing the Hermes revision, retain the nixpkgs revision from that
revision's upstream `flake.lock`. Removing a previous `follows` override alone
can select the latest nixpkgs rather than restoring the upstream lock. Restore
the upstream revision with:

    nix flake lock --override-input hermes-agent/nixpkgs github:NixOS/nixpkgs/<upstream-locked-revision>

The Hermes integration check enforces this pairing. Do not work around header
mismatches by blindly accepting the reported replacement hash.

## Validation and activation

    make fmt-check
    make eval-check
    make check

These do not activate the configuration. After a successful build:

    make switch HOST=zaros
    systemctl --user status hermes-backend.service

The desktop launcher is `hermes-desktop`; the CLI is `hermes`. No provider API
call is needed to evaluate or build the configuration.

After activation, close and reopen the desktop application to pick up the new
launcher and shared-backend connection. Existing running desktop processes are
not rerouted automatically. No activation or service restart is performed by
the flake checks.

`checks.x86_64-linux.hermes-agent` checks settings, activation order, package
availability, credentials preservation and disabled hosts.
`checks.x86_64-linux.hermes-runtime-state` exercises disposable token/skill
initialization and inspects the generated desktop/backend launchers.
