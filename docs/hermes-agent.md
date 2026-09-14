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

The desktop shares state with the dashboard, but upstream starts its own backend
unless `services.hermes-agent.backend.sessionTokenFile` is configured. To use one
backend process, supply a private runtime token file via that option; do not put
its contents or a Nix path literal in the repository. Both launchers read the
same token at runtime.

## Configuration and credentials

The feature preserves the selected model, `openai/gpt-5.6-sol`. Home Manager
merges declared settings into the writable config on activation; undeclared
settings are preserved. The upstream managed-mode marker makes some interactive
configuration commands refuse changes, so change Nix-managed settings here and
rebuild.

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
