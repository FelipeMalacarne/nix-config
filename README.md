# nix-config

Felipe's personal NixOS/nix-darwin configuration. It follows a feature-first,
dendritic composition model: hosts
compose reusable profiles and features without duplicating policy.

## Hosts

| Host | OS | Role |
|---|---|---|
| `zaros` | NixOS, x86_64 | Desktop, gaming and development |
| `saradomin` | NixOS, x86_64 | Headless home server |
| `saradomin-vm` | NixOS, x86_64 | Server VM variant |
| `macbook` | nix-darwin, Apple Silicon | Development laptop |

Zaros defaults to **Hyprland (UWSM-managed) + Noctalia**, with **Noctalia Greeter**
for login. Experimental Umbriel and i3/Xorg remain selectable alternatives.

Saradomin's DNS architecture and router setup are documented in
[`docs/adguard-home.md`](docs/adguard-home.md).

The shared, opt-in AI memory workflow and outage/recovery plan are documented in
[`docs/ai-memory.md`](docs/ai-memory.md).

## Architecture

The dependency direction is **host -> profile -> feature -> upstream module**.
Hosts own machine facts and explicitly import profiles and selected features;
profiles compose features and policy; features must not depend on profiles or
hosts. `hosts/` contains the four concrete host directories.
`modules/flake/configurations.nix` explicitly constructs the NixOS and
nix-darwin configuration outputs from those hosts.

Features are grouped into five domains: `system`, `desktop`, `services`,
`programs`, and `applications`. A feature stays cohesive and cross-platform
within its domain. Its excluded local `config/` directory is for internal
implementation files, manually imported by the discovered feature entrypoint.

`modules/profiles/` contains the `base`, `desktop`, `development`, `ai`, and `server`
compositions. `base` provides shared policy without optional system integrations;
`desktop` exposes i3, Hyprland, Umbriel, Noctalia and Caelestia capabilities plus
shared graphical applications, but does not select a login manager;
`development` provides programming and Kubernetes tools without selecting AI
clients. `ai` composes OpenCode, Claude Code, Codex, GitHub Copilot CLI and the
SOPS-backed ai-memory client; macbook and zaros explicitly import that platform
profile, which forwards its Home Manager composition. Hermes remains an optional
host selection, and ai-usagebar is not included. `server` provides headless
base/server policy. `server` does not
implicitly enable optional services: hosts select them through feature imports.

Platform profiles forward their Home Manager composition to the primary user.
Hosts select a platform profile once; additional Home Manager imports are for
independently selected user-only features, not a second copy of the profile.

Generic SSH, programming and Kubernetes tooling do not provision secrets.
Hosts explicitly import `ssh-credentials`, `programming-credentials` and
`k8s-credentials` when they need the existing SOPS-backed integration. Credential
companions import their own SOPS prerequisite, as does Restic. The default base
and server compositions therefore work without system SOPS integration.

Shared SSH inventory defaults merge per setting. For example, overriding
`my.infrastructure.ssh.hosts."github.com".IdentityFile` preserves the other
settings for GitHub and all unrelated hosts.

OpenClaw's configuration and flake dependency have been retired. Existing runtime
data and the encrypted legacy credential are preserved; their deletion or
revocation is a separate operation.

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
defaults. `desktop` owns the graphical stack. Importing a registered feature
module activates it; automatic registration alone does not. Hosts opt into
optional integrations directly, while profiles compose shared selections:

```nix
imports = [
  self.modules.nixos.docker
  self.modules.nixos.wol
];

my.wol.interface = "enp12s0";
```

Typed options configure imported features, such as `my.wol.interface` and
`my.restic.paths`. Feature-specific options are available only when the module
is imported; removing a feature also means removing its settings. There is no
additional `my.<feature>.enable` selector. Enable flags remain appropriate for
optional subfeatures such as `my.hermes-agent.web.enable`.

The optional [Craft suite](docs/artcraft.md#available-apps) documents every app,
its purpose, and its `my.artcraft.<app>.enable` flag. Configure these selectors
after importing `self.modules.nixos.artcraft`. Every app defaults to
disabled; Zaros selects only FilmCraft. Packages can also be tested independently
with `nix run 'path:.#filmcraft'`.
Use `make artcraft-updates`, `make artcraft-update APPS=filmcraft`, and
`make artcraft-check` to maintain the pinned suite.

Desktop sessions are selected with `my.desktop.sessions`; `my.desktop.defaultSession`
must be a member of that list. Zaros selects `[ "umbriel" "hyprland" "i3" ]`
with default `"hyprland"`. Each compositor maps that default to its native login
identifier: `umbriel`, `hyprland-uwsm`, or `none+i3`.

`my.desktop.shell` selects `noctalia`, `caelestia`, or `none`, independently of the
login manager. Providers own their commands, packages, settings and startup.
Noctalia supports both Wayland compositors: Hyprland's startup Lua launches the
configured binary once through `uwsm app`; Umbriel's native autostart launches
the same binary once directly. There is no shared Noctalia systemd startup unit.
Caelestia uses its official HM unit scoped to the Hyprland UWSM target and is not
supported with Umbriel. X11-only selections require `shell = "none"`.

Umbriel's `start-umbriel` owns `umbriel.service` and `umbriel-session.target`;
do not wrap it in UWSM. Hyprland retains its UWSM lifecycle. Hypridle is scoped to
`wayland-session@hyprland.desktop.target`; Swayidle is scoped to
`umbriel-session.target`. Each locks after 180 seconds and turns displays off
after 240 seconds using its compositor's DPMS commands. Noctalia's own idle
behavior is disabled. Portals route per desktop (`umbriel;gtk`, `hyprland;gtk`)
with GTK as the common fallback.

Monitor facts live in `hosts/zaros/desktop.nix`. Umbriel matches the exact
make/model/serial in `match.waylandDescription`, not connector names. The main
identity is `Samsung Electric Company Odyssey G61SD HNBYB00003` (live Wayland
probe on DP-4); the portrait secondary is
`Samsung Electric Company LS27A600U HNMW900149` (historically confirmed,
currently disconnected). Its 90-degree rotation and workspaces 6-9 remain
declared. The original XRandR outputs DP-1 and HDMI-A-1 stay separate, with
existing modes, refresh rates and positions preserved.

Monitor requirements follow the selected sessions: Wayland-only hosts need no
XRandR connector and may use HiDPI scaling; i3 selections still require their
XRandR identity and scale 1. Desktop application bindings and Dolphin share
`my.desktop.terminalCommand` and `my.desktop.terminalDesktopId`; override both
together when selecting a different compatible terminal.

The desktop profile exposes both Noctalia and Caelestia capabilities, but only
the selected provider is activated on Zaros. Adding a provider requires a
provider aspect, a command registry entry, an explicit desktop profile import,
and variant checks.

Noctalia uses the native v5 package and `programs.noctalia` Home Manager module.
Reusable UI preferences live in
`modules/features/desktop/noctalia/config/settings.toml`. Nix reads that baseline
and supplies a Stylix-derived palette, dynamic fonts, opacity, home-directory
paths, and initial wallpaper to produce `~/.config/noctalia/config.toml`. Startup
and keybindings use the same configured package and the `noctalia msg` interface.
Session-scoped Hypridle/Swayidle own idle timeouts.

The old v4 JSON settings and QML plugins are not compatible with v5. The built-in
screenshot widget replaces the old screenshot plugin, but recording, model usage,
KDE Connect, Docker, and Tailscale widgets need separately selected native plugins.
The old JSON export helper `scripts/noctalia2nix.go` is v4-only; use
`noctalia config export` for the merged v5 TOML settings. GUI changes are stored
in `~/.local/state/noctalia/settings.toml` and override the declarative settings.
The feature uses `bar.default` to merge with existing GUI bar settings rather
than create a second bar. Saved wallpaper paths also take precedence, including
per-monitor paths; an old path to a missing file must be updated in the UI or with
`noctalia msg wallpaper-set <path>`.
Do not reuse the old JSON export as v5 configuration.

### Noctalia UI workflow

Edit preferences in Noctalia's settings UI; changes apply immediately and persist
across rebuilds in the writable settings override. No rebuild or export is needed
just to keep using those changes. To capture them as the repository's baseline:

```sh
make noctalia-export
git diff -- modules/features/desktop/noctalia/config/settings.toml
make check
```

The exporter uses the pinned shell's `config export merged`, not the full defaults
dump. It validates a cleaned temporary file before atomically replacing the TOML
baseline. It never activates the system, reloads Noctalia, or changes the live
settings override. Subsequent builds use the new baseline; existing GUI overrides
still win until you reset those preferences in the UI.

The shared export excludes Nix-managed values, monitor/device identifiers,
desktop/lock-screen widget placements, wallpaper paths, calendar accounts, and
plugin-specific configuration. Those local settings stay on the machine; enabled
plugin IDs and reusable core preferences are retained. Known obsolete native
settings are cleaned, and a `main`/`default` duplicate bar is rejected rather than
silently exported. Review the diff before committing: custom commands, labels,
and retained widget/provider settings can still contain private information.

### Login manager

Zaros explicitly imports `self.modules.nixos.noctalia-greeter`; the desktop
profile imports neither Greeter nor SDDM. Greeter forwards the native default
session and discovers all retained sessions. i3 uses a scoped X11 helper that
passes the generated NixOS `xserverrc` explicitly to installed `startx`; its
projected session entry wraps the original legacy WM argument with `sessionData.wrapper` and
`DESKTOP_SESSION=none+i3`, preserving Home Manager and NixOS session setup.
i3 owns its XRandR topology, so it does not depend on SDDM's setup script.

Login requires authentication: no autologin or greetd `initial_session` is
configured. Appearance sync from Noctalia's UI also requires administrator
authentication through the packaged Polkit policy and `secure-sync-v1` helper.
`passwordless-sync-users` stays empty. Greeter theme, palette and wallpaper are
intentionally left sync-controlled rather than pinned by Nix; keyboard and
monitor facts remain declarative. Selecting another shell does not remove Greeter.

To revert to SDDM, replace Zaros's explicit `noctalia-greeter` import with
`self.modules.nixos.sddm` and choose the desired sessions/default. Do not enable
both login managers. This is a configuration change, not permission to deploy.

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

Use `nix develop path:.` for the native validation tools (Make, Nix, formatter and
linters). Per-system package policy is declared in the flake; validation does
not need `NIXPKGS_ALLOW_UNFREE` or whole-flake `--impure` evaluation.

```bash
make fmt             # pinned treefmt formatter
make fmt-check       # formatting check
make eval-check      # fast, no-build evaluation check
make check           # full flake check and relevant builds
make build-all       # all NixOS closures (Linux only)
make build-darwin    # MacBook closure
make build HOST=zaros
```

`make build-all` and `make build-darwin` build
`packages.<native-system>.host-closures`, derived from the explicit configuration
outputs. Adding a host does not require editing another Make host list.

On Darwin, Firefox uses its upstream native profile directory under
`Library/Application Support/Firefox`, rather than Linux's `.mozilla/firefox`.
No browser data is migrated by this refactor: review existing profiles before
activation. The optional ChatGPT feature supports Apple Silicon Darwin only and
is not selected on Zaros or MacBook.

SketchyBar's CPU helper is built from source as `packages.aarch64-darwin.sketchybar-helper`;
the generated startup configuration never compiles inside the linked config directory.
Darwin hotkeys keep `alt+shift+w` for quit and `alt+shift+x` for warp-next;
top-edge resize uses `alt+ctrl+w`, and x-axis mirror uses `alt+ctrl+shift+x`.

Activation commands remain guarded: `switch`, `test`, and `boot` require the
local hostname unless `DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1` is explicit, while
rollback is always local-host-only. Direct deployment commands are:

```bash
sudo nixos-rebuild switch --flake .#zaros
darwin-rebuild switch --flake .#macbook
```

## Extending it

Add a feature entrypoint under the appropriate `modules/features/<domain>/`,
register its module, and compose it in a profile or host. Its import should
activate the feature; add typed options for configurable settings rather than
a second activation selector. Put large implementation files in a
feature-local `config/` directory and import them from the entrypoint. Add a
desktop provider by implementing its aspect, shell command registry entry, and
completeness assertion. Add a host directory under `hosts/`, then update
`modules/flake/configurations.nix` and its behavioral expectations. Native closure
checks, the build selector and directory/output consistency follow automatically.

Keep feature checks beside their feature, using excluded implementation files
under `config/` where useful. Shared synthetic fixtures live in
`modules/checks/config/`; repository checks own concrete host selections and
hardware-preservation expectations. Do not hide required integrations by adding
them to every fixture.

## Validation and deferred work

Use `make eval-check` for evaluation, `make fmt-check` for formatting, and
`make check` or `nix flake check path:.` for full validation. CI runs
the full check natively on Linux and Apple-Silicon macOS. Native graphical
session, backup/restore, deployment and security-runtime checks remain
operational follow-ups. Password-hash ownership, SSH/firewall policy, broad
Tailscale trust, Disko device safety, Darwin SOPS bootstrap and backup/restore
verification are deliberately deferred.

Linux CI includes `desktop-sessions` (supported/rejected composition variants),
`umbriel-config` (generated TOML validated by the native CLI), and
`greeter-sessions` (actual upstream discovery/argv/environment code and installed
`startx` server selection with mocked xinit/Xorg, including declarative server
arguments, seat/VT, Xauth and client routing). These checks do not launch a
compositor, Xorg, or a physical login session. Existing shell-provider, Lua and TOML-export checks
remain in place.

Real NVIDIA rendering, login, both physical monitors, suspend/resume, gaming,
Xwayland and portal capture remain deferred pending explicit approval. A future
activation should be a controlled next-boot trial with a known-good generation
and TTY recovery available, not a live greeter restart. Building does not authorize
`boot`, reboot, logout, activation or any service restart.
