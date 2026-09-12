# nix-config

Felipe's personal NixOS/nix-darwin configuration. It is feature-first: hosts
compose reusable profiles and features without duplicating policy.

## Hosts

| Host | OS | Role |
|---|---|---|
| `zaros` | NixOS, x86_64 | Desktop, gaming and development |
| `saradomin` | NixOS, x86_64 | Headless home server |
| `saradomin-vm` | NixOS, x86_64 | Server VM variant |
| `macbook` | nix-darwin, Apple Silicon | Development laptop |

## Architecture

The dependency direction is **host -> profile -> feature -> upstream module**.
Hosts own machine facts and activation selections; profiles compose modules and
policy; features must not depend on profiles or hosts. `hosts/` contains the
four concrete host directories. `modules/flake/configurations.nix` explicitly
constructs the NixOS and nix-darwin configuration outputs from those hosts.

Features are grouped into five domains: `system`, `desktop`, `services`,
`programs`, and `applications`. A feature stays cohesive and cross-platform
within its domain. Its excluded local `config/` directory is for internal
implementation files, manually imported by the discovered feature entrypoint.

`modules/profiles/` contains the `base`, `desktop`, `development`, and `server`
compositions. `base` provides shared policy and the optional-feature catalog;
`desktop` provides the graphical stack; `development` provides development
tools; and `server` provides headless base/server policy. `server` does not
implicitly enable optional services: host `my.<feature>.enable` flags remain the
activation decisions.

`import-tree` discovers Nix files under `modules/`, except paths matching
`*/config/*`. Feature entrypoints are discovered automatically and manually
import their excluded implementation files. A feature registers the relevant
`flake.modules.nixos.<aspect>`, `flake.modules.darwin.<aspect>`, and/or
`flake.modules.homeManager.<aspect>` entry. Flake-parts composition uses
`config.flake.modules`; plain hosts consume the final `self.modules`. Discovery
is automatic, but registration and activation/composition remain explicit.

`modules/inventory/infrastructure.nix` is typed personal SSH and Kubernetes
data. It is inventory only, not generated host composition.

## Options and composition

`base` owns identity, core policy, theming, shell, Git, SSH, editor and CLI
defaults, and imports a default-disabled optional-feature catalog. Importing
`base` makes optional feature options available; host `my.<feature>.enable`
flags are the single activation decision. `desktop` owns the graphical stack.
Optional system integrations use typed options such as `my.docker.enable` and
`my.gaming.enable`.

Desktop sessions are selected with `my.desktop.sessions`. The shell selector
supports registered providers `noctalia`, `caelestia`, or `none`; Zaros selects
Noctalia. Each provider owns its commands and all provider-specific packages,
settings, and startup behavior. Caelestia uses its official HM systemd unit;
Noctalia owns its current Lua startup. Hyprland consumes the typed command
contract and remains provider-neutral.

The desktop profile exposes both Noctalia and Caelestia capabilities, but only
the selected provider is activated on Zaros. Adding a provider requires a
provider aspect, a command registry entry, an explicit desktop profile import,
and variant checks.

## Setup and secrets

The encrypted file is `secrets/secrets.yaml`, managed by SOPS and age. Bootstrap
the host key without putting it in shell history or printing it:

```bash
sudo install -d -m 700 /var/lib/sops-age
sudoedit /var/lib/sops-age/keys.txt
sudo chmod 600 /var/lib/sops-age/keys.txt
make secrets
```

The key must match `.sops.yaml`. CI never decrypts secrets.

## Safe commands

```bash
make fmt             # pinned treefmt formatter
make fmt-check       # formatting check
make eval-check      # fast, no-build evaluation check
make check           # full flake check and relevant builds
make build-all       # all NixOS closures (Linux only)
make build-darwin    # MacBook closure
make build HOST=zaros
```

Activation commands remain guarded: `switch`, `test`, and `boot` require the
local hostname unless `DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1` is explicit, while
rollback is always local-host-only. Direct deployment commands are:

```bash
sudo nixos-rebuild switch --flake .#zaros
darwin-rebuild switch --flake .#macbook
```

## Extending it

Add a feature entrypoint under the appropriate `modules/features/<domain>/`,
register its module, and compose it in a profile or host. Add a typed enable
option for an optional system integration. Put large implementation files in a
feature-local `config/` directory and import them from the entrypoint. Add a
desktop provider by implementing its aspect, shell command registry entry, and
completeness assertion. Add a host directory under `hosts/`, then update
`modules/flake/configurations.nix` and the appropriate checks/Make target.

## Validation and deferred work

Use `make eval-check` for evaluation, `make fmt-check` for formatting, and
`make check` or `nix flake check --impure path:.` for full validation. CI runs
the full check natively on Linux and Apple-Silicon macOS. Native graphical
session, backup/restore, deployment and security-runtime checks remain
operational follow-ups. Password-hash ownership, SSH/firewall policy, broad
Tailscale trust, Disko device safety, Darwin SOPS bootstrap and backup/restore
verification are deliberately deferred.
