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
- `desktop` — audio, network, i3, Hyprland, Umbriel, Noctalia and Caelestia
  capabilities, Firefox, Dolphin, Ghostty, KDE Connect and Bitwarden. Hosts
  explicitly select the login manager; the profile imports neither Greeter nor SDDM.
- `development` — programming and Kubernetes tooling.
- `server` — headless base/server policy; it does not implicitly enable optional
  services. Hosts select those services through explicit feature imports.

Core and shared Home Manager policy live under
`modules/features/system/core/` (with internals in its `config/`). Noctalia's
registration, settings and startup live under
`modules/features/desktop/noctalia/`; Caelestia's provider lives under
`modules/features/desktop/caelestia/`; Hyprland implementation and Lua live
under `modules/features/desktop/hyprland/`; Umbriel lives under
`modules/features/desktop/umbriel/`. Desktop sessions use
`my.desktop.sessions` and `my.desktop.defaultSession` (must be selected), forwarded
to HM and mapped to native IDs `umbriel`, `hyprland-uwsm`, and `none+i3`.
The shell selector is `my.desktop.shell =
"noctalia"`, `"caelestia"`, or `"none"` with typed commands. Zaros selects
Noctalia. Providers own their commands and all provider-specific package,
settings, and startup behavior. Caelestia uses its official HM systemd unit and
supports Hyprland only. Noctalia starts the same configured binary once through
Hyprland's Lua/UWSM app startup or Umbriel's direct native autostart, with no
shared Noctalia systemd unit. Both compositors stay provider-neutral. X11-only
selections require shell `none`. Umbriel's `start-umbriel` owns its native
`umbriel.service`/`umbriel-session.target`; never wrap it in UWSM. Hypridle targets
`wayland-session@hyprland.desktop.target`; Swayidle targets `umbriel-session.target`,
both with 180-second lock and 240-second DPMS timeouts. Portals route per desktop
with a GTK fallback.
Adding a provider requires an aspect, registry entry, explicit desktop-profile
import, and variant checks.

Noctalia Greeter is independent of shell/compositor selection. Zaros explicitly
imports `noctalia-greeter`; login has no autologin/`initial_session`, and appearance
sync requires administrator authentication (`auth_admin`, `secure-sync-v1`, empty
`passwordless-sync-users`). Keep theme/palette/wallpaper sync-controlled. The i3
fallback owns Xorg/topology; Greeter's scoped X11 helper passes the generated
xserverrc explicitly to installed startx and uses a projected
entry calling NixOS `sessionData.wrapper` with the original legacy WM argument and
`DESKTOP_SESSION=none+i3`. To revert, replace the host's Greeter import with the
explicit `sddm` feature; never enable both login managers.

Zaros's exact Wayland monitor identities include serials: main
`Samsung Electric Company Odyssey G61SD HNBYB00003` (live DP-4 probe) and portrait
secondary `Samsung Electric Company LS27A600U HNMW900149` (historically confirmed,
currently disconnected). Preserve separate XRandR outputs DP-1/HDMI-A-1 and the
existing modes, positions, rotations and workspace assignments; do not substitute
connector names for Umbriel identities.

## Hosts

- `zaros`: NixOS desktop defaulting to Umbriel + Noctalia and Noctalia Greeter,
  with Hyprland/UWSM and i3 alternatives, gaming, NVIDIA, development and server
  integrations; Sunshine is available but not selected.
- `saradomin`: headless NixOS home server with k3s, Disko, SSH and Tailscale.
- `saradomin-vm`: NixOS VM variant using the server profile, OpenSSH and Tailscale.
- `macbook`: nix-darwin development laptop with yabai, skhd and sketchybar.

To extend the repository, put a feature in its domain and keep host-specific
facts in `hosts/<name>/`. Compose reusable policy in a profile; select optional
integrations by importing their registered modules in a host or profile. Update
`modules/flake/configurations.nix` when adding a host.

## AI workflow

ai-memory is selected as a private server on saradomin and a Home Manager client
on macbook/zaros. Its single feature lives in `modules/features/services/ai-memory/`,
with server/client internals under the excluded `config/` directory.
See `docs/ai-memory.md` for pairing, privacy, outage recovery and
deployment acceptance gates. Capture is allowlist-only; this repository's marker
uses workspace `personal`, project `nix-config`. The MCP bridge is static: pass
both explicitly on project-scoped calls. Repository instructions and current
source outrank recalled history. If memory is unavailable, continue locally;
never start a competing server. Nix owns integrations; do not run live ai-memory
installers or self-updates. The former setup command/wiki skill are retired;
do not scaffold a parallel `docs/ai/` wiki.
The shared bearer is SOPS-encrypted in `secrets/ai-memory.yaml`; hosts decrypt it
at `/run/secrets/ai-memory-token` with service/user-only ownership. Clients link
their native `auth-token` path to that runtime secret. Never copy its plaintext
into configuration, prompts or the Nix store, or rotate it with queued captures.

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
Linux checks `desktop-sessions`, `umbriel-config`, and `greeter-sessions` cover
composition, native CLI config validation, upstream session discovery and the
installed startx parser with mocked xinit/Xorg, verifying configured server
arguments, seat/VT, Xauth and client routing. They never launch physical sessions.

Agents must finish formatting, evaluation and affected-closure builds before
claiming a configuration is ready. Activation (`switch`, `test`, `boot`), rollback,
reboot, remote deployment and session-interrupting service restarts require
explicit user approval; a request to edit or build is not approval to deploy.
Use project Nix development shells for dependencies, temporary `nix shell`
environments for one-off tools, and private venvs/uv for scratch Python. Never
install into system Python or modify the Nix store. Save reusable verified
lessons as reviewed skills rather than adding task history to global memory.

Native NVIDIA/login/monitor/suspend/gaming/Xwayland/portal smoke tests remain
deferred pending approval, as do backup/restore and hardening. Any future desktop
activation should use a controlled next-boot trial with a known-good generation
and TTY recovery, not a live greeter restart; do not execute boot/reboot/logout
without explicit approval. In particular, do not change password-hash ownership,
SSH/firewall policy, Tailscale trust, Disko device safety, Darwin SOPS bootstrap, or backup
verification as part of routine refactors.
