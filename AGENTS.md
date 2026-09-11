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

- Sunshine (game streaming server) runs on **zaros** only (needs NVENC).
- Games and GPU-accelerated workloads run on **zaros** only.

## Architecture and module system

The dependency direction is **host -> profile -> feature -> upstream module**.
Hosts own machine facts and activation selections. Profiles compose modules and
policy. Features must not depend on profiles or hosts.

Features live in the five domains `system`, `desktop`, `services`, `programs`,
and `applications`; each remains cohesive and cross-platform within its domain.
Feature-local `config/` directories are excluded from discovery and contain
internal implementation files imported by their entrypoint.

All `.nix` files under `modules/` are auto-discovered by `import-tree`, except
paths matching `.*/config/.*`. Features live at
`modules/features/<domain>/<feature>.nix` or in a same-named directory; directory
entrypoints are discovered automatically and import internal `config/` files
manually.

Each feature registers itself as `flake.nixosModules.<name>`,
`flake.darwinModules.<name>`, and/or `flake.homeModules.<name>`. Use only the
platform registrations the implementation supports.

Optional system integrations conventionally expose a typed, default-disabled
`my.<feature>.enable` option. Hosts explicitly enable selected integrations.
The restic option is `my.restic` (not `myConfig.restic`).

`hosts/` contains concrete machines. `modules/flake/configurations.nix`
explicitly constructs all NixOS and nix-darwin outputs from those host
directories. `modules/inventory/infrastructure.nix` contains typed personal
SSH/Kubernetes data only; it is not generated host composition.

## Profiles and desktop

- `base` — feature-local core, theming, zsh, git, ssh, nvim, CLI, btop, yazi,
  plus a default-disabled optional-feature catalog. Importing `base` exposes
  those options; host `my.<feature>.enable` flags alone activate them.
- `desktop` — audio, network, Hyprland, Noctalia, Firefox, Dolphin,
  Ghostty, KDE Connect and Bitwarden.
- `development` — programming and Kubernetes tooling.
- `server` — headless base/server policy; it does not implicitly enable optional
  services. Host `my.<feature>.enable` flags remain activation decisions.

Core and shared Home Manager policy live under
`modules/features/system/core/` (with internals in its `config/`). Noctalia's
registration, settings and startup live under
`modules/features/desktop/noctalia/`; Hyprland implementation and Lua live
under `modules/features/desktop/hyprland/`. Desktop sessions use
`my.desktop.sessions`, and the shell contract is `my.desktop.shell = "noctalia"`
or `"none"` with typed commands.

## Hosts

- `zaros`: NixOS desktop with Hyprland + Noctalia, gaming, Sunshine, NVIDIA,
  development and server integrations.
- `saradomin`: headless NixOS home server with k3s, Disko, SSH and Tailscale.
- `saradomin-vm`: NixOS VM variant using the base profile.
- `macbook`: nix-darwin development laptop with yabai, skhd and sketchybar.

To extend the repository, put a feature in its domain and keep host-specific
facts in `hosts/<name>/`. Compose reusable policy in a profile; select optional
integrations with the host's typed `my.<feature>.enable` option. Update
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

Native graphical-session smoke tests, backup/restore, and hardening remain
deferred. In particular, do not change password-hash ownership, SSH/firewall
policy, Tailscale trust, Disko device safety, Darwin SOPS bootstrap, or backup
verification as part of routine refactors.
