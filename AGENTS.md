# NixOS Configuration

Felipe's system configuration repo. Uses flake-parts, home-manager, stylix,
and nix-darwin.

## Hardware

### zaros (desktop / main workstation)
- CPU: AMD Ryzen 7 7800X3D
- GPU: NVIDIA RTX 4070 SUPER (NVENC capable)
- Storage: 1TB NVMe + 2TB NVMe
- OS: NixOS

### saradomin (home server / mini PC)
- CPU: Intel N95
- RAM: 16GB
- Storage: 512GB NVMe
- OS: NixOS
- Purpose: home server (no games/gaming GPU — do not run Sunshine/GPU-encoding services here)

### macbook
- MacBook Pro (Apple Silicon) — nix-darwin

## Key services

- Sunshine (game streaming server) is supported on **zaros** only (needs NVENC),
  but is currently not selected.
- Games and GPU-accelerated workloads run on **zaros** only.

## Architecture and module system

The dependency direction is **host -> profile -> feature -> upstream module**.
Hosts own machine facts and explicitly import profiles and selected features.
Profiles compose features and policy. Features must not depend on profiles or
hosts.

Features live in the five domains `system`, `desktop`, `services`, `programs`,
and `applications`; each remains cohesive and cross-platform within its domain.
Feature-local `config/` directories are excluded from discovery and contain
internal implementation files imported by their entrypoint.

All `.nix` files under `modules/` are auto-discovered by `import-tree`, except
paths matching `.*/config/.*`. Features live at
`modules/features/<domain>/<feature>.nix` or in a same-named directory; directory
entrypoints are discovered automatically and import internal `config/` files
manually.

Each feature registers itself as `flake.modules.nixos.<aspect>`,
`flake.modules.darwin.<aspect>`, and/or `flake.modules.homeManager.<aspect>`.
Flake-parts modules compose through `config.flake.modules`; plain hosts consume
the final `self.modules`. Registration is auto-discovered, but activation and
composition stay explicit. Use only the platform registrations the
implementation supports.

Importing a registered feature module activates that feature. Do not add a
redundant `my.<feature>.enable` selector or default-import optional features into
`base`. Keep typed options for settings such as `my.wol.interface` and
`my.restic.paths`; feature-specific settings require the corresponding import.
Enable flags remain appropriate for optional subfeatures such as
`my.hermes-agent.web.enable`. The restic namespace is `my.restic`.

`hosts/` contains concrete machines. `modules/flake/configurations.nix`
explicitly constructs all NixOS and nix-darwin outputs from those host
directories. `modules/inventory/infrastructure.nix` contains typed personal
SSH/Kubernetes data only; it is not generated host composition.

## Profiles and desktop

- `base` — feature-local core, theming, zsh, git, ssh, nvim, CLI, btop, yazi.
  It does not import optional system integrations.
- `desktop` — audio, network, Hyprland, Noctalia and Caelestia capabilities,
  Firefox, Dolphin, Ghostty, KDE Connect and Bitwarden.
- `development` — programming and Kubernetes tooling.
- `server` — headless base/server policy; it does not implicitly enable optional
  services. Hosts select those services through explicit feature imports.

Core and shared Home Manager policy live under
`modules/features/system/core/` (with internals in its `config/`). Noctalia's
registration, settings and startup live under
`modules/features/desktop/noctalia/`; Caelestia's provider lives under
`modules/features/desktop/caelestia/`; Hyprland implementation and Lua live
under `modules/features/desktop/hyprland/`. Desktop sessions use
`my.desktop.sessions`, and the shell selector is `my.desktop.shell =
"noctalia"`, `"caelestia"`, or `"none"` with typed commands. Zaros selects
Noctalia. Providers own their commands and all provider-specific package,
settings, and startup behavior. Caelestia uses its official HM systemd unit;
Noctalia owns its current Lua startup, while Hyprland stays provider-neutral.
Adding a provider requires an aspect, registry entry, explicit desktop-profile
import, and variant checks.

## Hosts

- `zaros`: NixOS desktop with Hyprland + Noctalia, gaming, NVIDIA, development
  and server integrations; Sunshine is available but not selected.
- `saradomin`: headless NixOS home server with k3s, Disko, SSH and Tailscale.
- `saradomin-vm`: NixOS VM variant using the server profile, OpenSSH and Tailscale.
- `macbook`: nix-darwin development laptop with yabai, skhd and sketchybar.

To extend the repository, put a feature in its domain and keep host-specific
facts in `hosts/<name>/`. Compose reusable policy in a profile; select optional
integrations by importing their registered modules in a host or profile. Update
`modules/flake/configurations.nix` when adding a host.

## Validation and deployment

```sh
make fmt
make fmt-check
make eval-check
make check
make build-all                 # Linux: all NixOS closures
make build-darwin              # MacBook closure
make switch HOST=zaros         # guarded activation
make secrets                   # edit SOPS secrets
```

`switch`, `test`, and `boot` are local-host-only by default; intentional
cross-host activation requires `DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1`. Rollback
never accepts cross-host overrides. CI runs `nix flake check --impure` on native
Linux and Apple-Silicon macOS and does not deploy or decrypt secrets.

Agents must finish formatting, evaluation and affected-closure builds before
claiming a configuration is ready. Activation (`switch`, `test`, `boot`), rollback,
reboot, remote deployment and session-interrupting service restarts require
explicit user approval; a request to edit or build is not approval to deploy.
Use project Nix development shells for dependencies, temporary `nix shell`
environments for one-off tools, and private venvs/uv for scratch Python. Never
install into system Python or modify the Nix store. Save reusable verified
lessons as reviewed skills rather than adding task history to global memory.

Native graphical-session smoke tests, backup/restore, and hardening remain
deferred. In particular, do not change password-hash ownership, SSH/firewall
policy, Tailscale trust, Disko device safety, Darwin SOPS bootstrap, or backup
verification as part of routine refactors.
