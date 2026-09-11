# nix-config

Felipe's personal NixOS/nix-darwin configuration. It is feature-first: host
files compose reusable features and profiles without duplicating policy.

## Hosts

| Host | OS | Role |
|---|---|---|
| `zaros` | NixOS, x86_64 | Desktop, gaming and development |
| `saradomin` | NixOS, x86_64 | Headless home server |
| `saradomin-vm` | NixOS, x86_64 | Server VM variant |
| `macbook` | nix-darwin, Apple Silicon | Development laptop |

## Layout

`modules/hosts/` contains host composition, `modules/profiles/` contains
bundles such as `base` and `desktop`, and `modules/features/` contains
self-registering features. Large features colocate implementation and
generated configuration, for example `features/core/`, `features/hyprland/`,
and `features/noctalia/`.

`import-tree` discovers Nix files under `modules/`, except paths matching
`*/config/*`. Feature entrypoints are discovered automatically and manually
import their excluded implementation files. A feature registers the relevant
`flake.nixosModules`, `flake.darwinModules`, and/or `flake.homeModules` entry.

## Options and composition

`base` owns identity, core policy, theming, shell, Git, SSH, editor and CLI
defaults, and imports a default-disabled optional-feature catalog. Importing
`base` makes optional feature options available; host `my.<feature>.enable`
flags are the single activation decision. `desktop` owns the graphical stack.
Optional system integrations use typed options such as `my.docker.enable` and
`my.gaming.enable`.

Desktop sessions are selected with `my.desktop.sessions`. The shell contract is
`my.desktop.shell = "noctalia"` or `"none"`; Hyprland consumes its typed command
contract and does not contain Noctalia-specific implementation knowledge.

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

Add a feature entrypoint under `modules/features/`, register its module, and
compose it in a host or profile. Add a typed enable option for an optional
system integration. Put large implementation files in a feature-local
`config/` directory and import them from the entrypoint. Add a desktop backend
by implementing the shell command contract and its completeness assertion.
Add a host under `modules/hosts/`, then add its closure to the appropriate
checks and Make target if it should be built routinely.

## Validation and deferred work

Use `make eval-check` for evaluation, `make fmt-check` for formatting, and
`make check` or `nix flake check --impure path:.` for full validation. CI runs
the full check natively on Linux and Apple-Silicon macOS. Native graphical
session, backup/restore, deployment and security-runtime checks remain
operational follow-ups. Password-hash ownership, SSH/firewall policy, broad
Tailscale trust, Disko device safety, Darwin SOPS bootstrap and backup/restore
verification are deliberately deferred.
