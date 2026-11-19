# NixOS Configuration

Felipe's system configuration repo: flake-parts, Home Manager, Stylix and
nix-darwin. This file holds the rules for changing it; `README.md` and `docs/`
describe how the features behave.

## Machines

- `zaros` — main NixOS workstation: Ryzen 7 7800X3D, RTX 4070 SUPER (NVENC),
  1 TB + 2 TB NVMe. Hyprland/UWSM and Umbriel sessions with the Noctalia shell
  and Noctalia Greeter, gaming, NVIDIA, development and AI integrations. i3 and
  Caelestia stay importable, but zaros does not import them.
- `saradomin` — headless NixOS home server: Intel N95, 16 GB RAM, 512 GB NVMe.
  k3s, Disko, AdGuard Home, SSH and Tailscale.
- `saradomin-vm` — VM variant of the server profile with OpenSSH and Tailscale.
- `macbook` — Apple Silicon nix-darwin laptop with yabai, skhd and SketchyBar.

Games and GPU-accelerated workloads run on zaros only. That includes Sunshine,
which needs NVENC and is available but not selected. Never put them on
saradomin; `checks.server-policy` enforces this.

## Architecture

Follow and implement the **dendritic pattern**: feature/aspect-oriented
flake-parts modules that co-locate related NixOS, nix-darwin and Home Manager
configuration. Robust, clean, explicit composition and idiomatic Nix best
practices are architectural requirements, not just file-layout preferences.
Prefer cohesive reusable modules, native upstream options and typed interfaces;
minimize duplication, unnecessary indirection and cross-layer coupling. Future
changes and refactors must preserve and improve this composition model.

The dependency direction is **host -> profile -> feature -> upstream module**.
Hosts own machine facts and explicitly import profiles and selected features.
Profiles compose features and policy. Features must not depend on profiles or
hosts.

### Layout

- `hosts/<name>/` — concrete machines. `default.nix` is the import manifest:
  only `imports` (local files, profiles, features grouped under topic comments)
  and per-user Home Manager `imports`; `checks.repository-structure` enforces
  it. `settings.nix` holds host facts and per-host settings. `hardware.nix`,
  `disk.nix` and `desktop.nix` stay beside them. `modules/flake/configurations.nix`
  constructs every NixOS and nix-darwin output explicitly; update it when adding
  a host.
- `modules/features/<domain>/` — features in eight topic domains. Each stays
  cohesive and cross-platform within its domain; never group features by
  platform.
  - `ai` — AI clients, skills, MCP servers, Hermes and the agent browser.
  - `dev` — Git, Docker, Kubernetes, Neovim, programming and toolchains.
  - `shell` — terminal tools, SSH client and zsh.
  - `desktop` — compositors, shells, login managers, audio and bars.
  - `apps` — graphical and everyday applications.
  - `games` — gaming and game tooling.
  - `services` — long-running daemons and network services.
  - `system` — core, hardware, secrets, theming and virtualization.
- `modules/profiles/` — `base`, `desktop`, `development`, `ai`, `server`.
- `modules/inventory/infrastructure.nix` — typed personal data: SSH hosts and
  authorized keys, Kubernetes clusters, and `machines.<name>` network facts (LAN
  and tailnet addresses, MagicDNS names, MAC addresses). It is data, not host
  composition. Hosts derive cross-machine values from it instead of repeating
  literals; defaults merge per leaf, so override single settings, never copies.
- `modules/checks/` — repository checks and shared check helpers.
- `modules/flake/` — outputs, formatter, development shell, package policy and
  repository paths.

### Features

A feature is either `<domain>/<aspect>.nix` or a directory `<domain>/<aspect>/`
with the entrypoint `<aspect>.nix`, an optional `checks.nix`, and everything else
(Nix helpers, scripts, data files, images) under `config/`. File names match an
aspect the file registers; companions such as `ssh-credentials` share their
feature's file. `checks.repository-structure` enforces this layout.

`import-tree` discovers every `.nix` file under `modules/` except paths matching
`.*/config/.*`; entrypoints import their `config/` files explicitly.

Each feature registers `flake.modules.nixos.<aspect>`,
`flake.modules.darwin.<aspect>` and/or `flake.modules.homeManager.<aspect>`, only
for platforms it supports. Flake-parts modules compose through
`config.flake.modules`; plain hosts consume the final `self.modules`.
Registration is automatic; activation and composition stay explicit.

`modules/flake-parts.nix` declares `flake.modules` exactly like upstream's
`flakeModules.modules`, but gives each registration a module `key`. An aspect
reached through several import paths therefore merges once, so a feature may
import what it depends on, as `openssh` imports `infrastructure`. Do not add
manual `key`s. Switch back to upstream once it sets a key itself.

Importing a registered feature module activates that feature, and nothing else
does. Profiles bundle only features that are always wanted together, never
alternatives. Sessions, shells, toolchains and optional applications stay
importable, and each host imports the ones it uses. `make catalog` lists every
aspect with the hosts that import it. `make inventory HOST=<host>` lists what one
host installs, grouped by aspect. Do not add a
redundant `my.<feature>.enable` selector or default-import optional features into
`base`. Keep typed options for settings such as `my.wol.interface` and
`my.restic.paths`; feature-specific settings require the corresponding import.
Enable flags remain appropriate for optional subfeatures such as
`my.ai.hermes.web.enable`.

Platform modules forward Home Manager aspects with
`home-manager.sharedModules = [ registry.homeManager.<aspect> ]`, using the final
`config.flake.modules.homeManager` aggregate so other dendritic fragments apply.
Use `home-manager.users.${user}` only to set per-user values. Platform profiles
forward their Home Manager profile; hosts must not repeat those imports. Keep
explicit Home Manager imports for independently selected user-only features.
When NixOS and Darwin registrations differ only slightly, write one
`platform:` function (as in `ssh.nix` and `k8s.nix`) rather than two copies.

Refer to encrypted SOPS files as `secretsDir + "/<file>.yaml"`, a flake-parts
module argument, not through `../` chains. Never derive repository paths from
`self` or package a directory containing Nix files (use a fileset, as Neovim
does): either makes a closure depend on unrelated source edits.

### Settings and profiles

Hermes settings live under `my.ai.hermes`; features own their options. ArtCraft uses the `artcraft-flake` input's native
`programs.artcraft` options. The restic namespace is `my.restic`.

- `base` — core, theming, zsh, git, ssh, Neovim, CLI, btop, yazi. No optional
  system integrations.
- `desktop` — audio, network, desktop foundation, Firefox, Dolphin, Ghostty,
  KDE Connect, Bitwarden. It imports no session, shell or login manager.
- `development` — the programming workbench and Kubernetes tooling, without AI
  clients or language toolchains.
- `ai` — explicit workstation composition of OpenCode, Claude Code, Codex and
  GitHub Copilot CLI. NixOS/Darwin imports forward the Home Manager profile.
  Hermes stays host-selected; ai-usagebar is deferred.
- `server` — headless base/server policy; it does not implicitly enable optional
  services. Hosts select those services through explicit feature imports.

Language stacks are `toolchain-<name>` Home Manager aspects. One package list per
stack in `modules/features/dev/toolchain/config/toolchains.nix` feeds both
the aspect and `devShells.<system>.<name>`, which other flakes reuse through
`inputsFrom`. Hosts import the stacks they use. Add a stack by adding one entry.

Generic SSH, programming and Kubernetes tooling do not provision credentials.
Hosts explicitly select `ssh-credentials`, `programming-credentials` and
`k8s-credentials` where needed; these companions, and Restic, import their own
SOPS prerequisite. Preserve existing secret paths, owners, modes and runtime
behavior when composing them.

## Checks

- Feature checks live beside their feature and evaluate synthetic fixtures. Use
  the perSystem arguments from `modules/checks/lib.nix`: `fixtures` (NixOS
  fixtures from `modules/checks/config/fixtures.nix`), `evalHome` (Home Manager
  modules for a throwaway user) and `mkAssertCheck name [ { assertion; message; } ]`,
  which reports every failure at once. Do not write new per-test harnesses or
  `assert … runCommand` chains.
- Concrete host expectations belong in `modules/checks/host-policy.nix`. Encode
  rules (servers stay headless, GPU workloads stay off servers, summaries use the
  subscription), never copies of values a host sets.
- Nix test helpers in `config/` are named `test-<topic>.nix`; Python tests keep
  `test_<topic>.py`.
- Host closure checks and `packages.<system>.host-closures` derive from the
  configuration outputs; never maintain a parallel host list.
- `desktop-sessions`, `umbriel-config` and `greeter-sessions` build variants by
  importing aspects and use zaros's monitor facts. The greeter fixture imports
  every session, i3 included. They validate composition and native config parsers
  with mocked xinit/Xorg and never launch a physical session.

## Desktop

`README.md` describes sessions, shell providers, idle, portals and the Greeter.
Preserve these rules:

- A session or shell is on exactly when the host imports its aspect. Each
  session aspect (`hyprland`, `umbriel`, `i3`) adds itself to
  `my.desktop.sessions` and forwards its Home Manager half. Each shell aspect
  (`noctalia`, `caelestia`) sets `my.desktop.shell` the same way, so importing
  two shells fails evaluation. Hosts set only `my.desktop.defaultSession` and
  monitors. Providers own their commands, packages, settings and startup;
  compositors stay provider-neutral. A new provider needs an aspect whose NixOS
  half sets the option and forwards its Home Manager half, a registry entry, a
  host import and variant checks. An X11-only selection must not import a shell.
- Never wrap Umbriel's `start-umbriel` in UWSM.
- Exactly one login manager. Zaros imports `noctalia-greeter`; to revert,
  replace that import with `sddm`. No autologin or `initial_session`;
  appearance sync stays admin-authenticated (`auth_admin`, `secure-sync-v1`,
  empty `passwordless-sync-users`) and theme/palette/wallpaper sync-controlled.
- Preserve zaros's monitor facts in `hosts/zaros/desktop.nix`. Umbriel matches
  exact make/model/serial descriptions, never connector names; the XRandR
  outputs DP-1/HDMI-A-1, modes, positions, rotations and workspaces stay as
  declared.

## AI clients and memory

- OpenCode and Claude Code import the shared `playwright-mcp`, `linear-mcp` and
  `github-mcp` Home Manager aspects and consume the native MCP registry. Never
  embed credentials in Nix or the store: Linear uses its official remote
  endpoint with client-managed OAuth; GitHub uses the official local server with
  a token from `gh` at runtime. Codex and Copilot CLI remain package-only;
  client-specific settings and plugins stay in their client features.
- OpenCode is CLI-only and tracks the upstream `production` branch through
  `flake.lock`; never substitute Nixpkgs V1 packages or migrate/copy databases
  as a routine fix. Test package changes with isolated HOME/XDG first: a build
  does not prove database compatibility or session behavior.
- Firefox is the daily browser and Google Chrome stays absent. On Linux,
  Chromium is the agent browser carrying the Claude in Chrome and Playwright
  Bridge extensions; web apps run in a separate `chromium-webapps` user-data-dir
  so agents never share personal logins.
- Claude's native `programs.claude-code.settings` renders a `settings.nix.json`
  baseline that activation rebases into a writable `settings.json`: unchanged
  defaults follow Nix, while local changes and deletions survive rebuilds. Never
  relink it into the store or force-overwrite user preferences; see
  `docs/claude-code.md` for migration, concurrency and rollback.
- Add skills only for concrete, specialized procedures or reference material;
  never generic advice or copies of this file. The `ai-skills` aspect publishes
  portable skills from `modules/features/ai/ai-skills/skills/` through each
  enabled client's native option; the optional `linear-issue-skill` aspect
  publishes the Linear issue workflow from the same tree (MacBook selects it;
  the AI profile and Zaros do not). Repository skills live in `.claude/skills/`,
  discovered by both clients, with distinct IDs when a global skill covers the
  same topic.
- Keep OpenClaw's encrypted credential and runtime state. Deleting them is not
  routine cleanup.

## Validation and deployment

```sh
make fmt
make fmt-check
make eval-check
make check
make inventory HOST=zaros      # aspects and packages one host installs
make catalog                   # every aspect and the hosts that import it
make build-all                 # Linux: all NixOS closures
make build-darwin              # MacBook closure
make switch HOST=zaros         # guarded activation
make secrets                   # edit SOPS secrets
```

The flake only sees files Git tracks: `git add` new files (no commit needed)
before evaluating. For a refactor meant to leave behavior unchanged, compare
each host's `system.build.toplevel.drvPath` before and after, and explain any
difference with `nix-diff`.

`switch`, `test`, and `boot` are local-host-only by default; intentional
cross-host activation requires `DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1`. Rollback
never accepts cross-host overrides. CI runs pure `nix flake check` on native
Linux and Apple-Silicon macOS and does not deploy or decrypt secrets.

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
