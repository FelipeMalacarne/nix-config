# Features Consolidation Refactor

**Date:** 2026-04-29
**Scope:** Consolidate all NixOS/home-manager modules into `modules/features/` with preset bundles. Macbook/darwin untouched.

## Problem

Three competing module patterns exist:

1. `modules/features/` — NixOS-level, uses `primaryUser` to wire both system + HM config
2. `modules/home/common/` — pure HM modules imported inside `home-manager.users.<user>.imports`
3. `modules/nixos/` — pure NixOS system modules

This creates confusion about where config lives, inconsistent patterns across modules, and long import lists in host configs. The color scheme wiring is fragile (buried in `home/common/default.nix`).

## Design

### Philosophy

One feature = one file. Each feature handles its own system config and home-manager config in one place, using `config.myConfig.primaryUser` to wire into the correct user. Presets bundle features into reusable profiles.

### Target Structure

```
modules/
├── options.nix
├── features/
│   ├── core.nix              # locale, tz, nix settings, boot, HM stateVersion
│   ├── theming.nix           # NEW — nix-colors, myConfig.colorScheme option
│   ├── zsh.nix               # shell + starship
│   ├── git.nix               # git identity (from home/common)
│   ├── ssh.nix               # SSH config (from home/common)
│   ├── nvim.nix              # neovim (from home/common)
│   ├── cli.nix               # merged: btop+theme, eza, zoxide, fzf, yazi+desktop-entry
│   ├── programming.nix       # merged: languages, dev tools, claude-code
│   ├── fonts.nix             # typography
│   ├── nvidia.nix            # GPU drivers
│   ├── gaming.nix            # merged: steam/proton + steam Millennium theming
│   ├── hyprland/
│   │   ├── default.nix       # WM + display manager + GTK
│   │   ├── binds.nix
│   │   ├── autostart.nix
│   │   ├── input.nix
│   │   ├── rules.nix
│   │   ├── monitors.nix
│   │   ├── envs.nix
│   │   ├── animations.nix
│   │   ├── wallpaper.nix     # hyprpaper (from home/desktop)
│   │   └── idle.nix          # hypridle (from home/desktop)
│   ├── noctalia.nix
│   ├── alacritty.nix
│   ├── firefox.nix           # browser + pywalfox (from home/desktop)
│   ├── dolphin.nix           # file manager (from home/desktop)
│   ├── audio.nix             # pipewire (from nixos/)
│   ├── network.nix           # NetworkManager (from nixos/)
│   ├── kdeconnect.nix        # phone integration (from nixos/)
│   └── tailscale.nix         # VPN (from nixos/)
├── presets/
│   ├── base.nix              # core, theming, zsh, git, ssh, nvim, cli, fonts
│   └── desktop.nix           # base + audio, network, hyprland, noctalia,
│                              # firefox, dolphin, alacritty, kdeconnect
├── darwin/                   # UNTOUCHED
└── home/darwin/              # UNTOUCHED
```

### Presets

Presets are thin import bundles. They layer: `base` is always included, `desktop` extends `base`.

```nix
# presets/base.nix
{
  imports = [
    ../features/core.nix
    ../features/theming.nix
    ../features/zsh.nix
    ../features/git.nix
    ../features/ssh.nix
    ../features/nvim.nix
    ../features/cli.nix
    ../features/fonts.nix
  ];
}
```

```nix
# presets/desktop.nix
{
  imports = [
    ./base.nix
    ../features/audio.nix
    ../features/network.nix
    ../features/hyprland
    ../features/noctalia.nix
    ../features/firefox.nix
    ../features/dolphin.nix
    ../features/alacritty.nix
    ../features/kdeconnect.nix
  ];
}
```

A future `presets/server.nix` would import `base.nix` + network + tailscale.

### Host Config After Refactor

```nix
# hosts/zaros/default.nix
{ pkgs, config, ... }:
let user = config.myConfig.primaryUser; in
{
  imports = [
    ./hardware.nix
    ../../modules/options.nix
    ../../modules/presets/desktop.nix
    ../../modules/features/nvidia.nix
    ../../modules/features/gaming.nix
    ../../modules/features/programming.nix
    ../../modules/features/tailscale.nix
  ];

  myConfig.colorScheme = "catppuccin-mocha";
  networking.hostName = "zaros";

  # ... host-specific config (docker, ollama, SSH, users, packages)
}
```

Down from 20+ imports to 6. Each import clearly communicates what makes this host unique.

### Feature Module Pattern

Every feature follows the same shape:

```nix
# modules/features/<name>.nix
{ config, pkgs, ... }:
let user = config.myConfig.primaryUser; in
{
  # NixOS-level config (if any)
  some.nixos.option = true;

  # Home-manager config (if any)
  home-manager.users.${user} = {
    # HM config here
  };
}
```

### Key Architectural Decisions

#### core.nix — HM Base Wiring

`core.nix` absorbs the home-manager wiring that currently lives in `hosts/zaros/default.nix`:

```nix
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
home-manager.backupFileExtension = "bak";
home-manager.users.${user}.home.stateVersion = "24.11";
```

This ensures every host that imports core gets consistent HM setup.

#### theming.nix — New Feature

Extracts color scheme wiring from `home/common/default.nix`. Defines `myConfig.colorScheme` at NixOS level, imports nix-colors HM module, and wires the palette into HM config. All features that use `config.colorScheme.palette` depend on this implicitly (enforced by presets always including it).

```nix
# features/theming.nix
{ config, inputs, lib, ... }:
let user = config.myConfig.primaryUser; in
{
  options.myConfig.colorScheme = lib.mkOption {
    type = lib.types.str;
    default = "catppuccin-mocha";
    description = "nix-colors scheme name.";
  };

  config.home-manager.users.${user} = {
    imports = [ inputs.nix-colors.homeManagerModules.default ];
    colorScheme = inputs.nix-colors.colorSchemes.${config.myConfig.colorScheme};
  };
}
```

#### Merges

| Target | Sources | Rationale |
|--------|---------|-----------|
| `cli.nix` | home/common/cli.nix + home/common/btop.nix + home/desktop/yazi.nix | All shell experience tools. btop theme belongs with btop config. yazi desktop entry belongs with yazi config. |
| `programming.nix` | current programming.nix + home/common/claude-code.nix | Claude Code is a dev tool. |
| `gaming.nix` | current gaming.nix + home/desktop/steam.nix | Millennium theming is Steam config. |
| `hyprland/` | current hyprland/ + home/desktop/wallpaper.nix + home/desktop/idle.nix | hyprpaper and hypridle are Hyprland ecosystem. |

#### Moves (no merge, just relocate + rewrite to feature pattern)

| Target | Source |
|--------|--------|
| `features/git.nix` | `home/common/git.nix` |
| `features/ssh.nix` | `home/common/ssh.nix` |
| `features/nvim.nix` | `home/common/nvim.nix` |
| `features/firefox.nix` | `home/desktop/firefox.nix` |
| `features/dolphin.nix` | `home/desktop/dolphin.nix` |
| `features/audio.nix` | `nixos/audio.nix` |
| `features/network.nix` | `nixos/network.nix` |
| `features/kdeconnect.nix` | `nixos/kdeconnect.nix` |
| `features/tailscale.nix` | `nixos/tailscale.nix` |

#### Files to Delete After Migration

- `modules/home/common/default.nix` — replaced by presets + theming
- `modules/home/common/git.nix` — moved to features
- `modules/home/common/nvim.nix` — moved to features
- `modules/home/common/cli.nix` — merged into features/cli.nix
- `modules/home/common/btop.nix` — merged into features/cli.nix
- `modules/home/common/ssh.nix` — moved to features
- `modules/home/common/claude-code.nix` — merged into features/programming.nix
- `modules/home/common/dev-tools.nix` — already superseded by features/programming.nix
- `modules/home/desktop/firefox.nix` — moved to features
- `modules/home/desktop/wallpaper.nix` — merged into features/hyprland/
- `modules/home/desktop/yazi.nix` — merged into features/cli.nix
- `modules/home/desktop/dolphin.nix` — moved to features
- `modules/home/desktop/idle.nix` — merged into features/hyprland/
- `modules/home/desktop/steam.nix` — merged into features/gaming.nix
- `modules/nixos/network.nix` — moved to features
- `modules/nixos/audio.nix` — moved to features
- `modules/nixos/desktop.nix` — empty placeholder, delete
- `modules/nixos/kdeconnect.nix` — moved to features
- `modules/nixos/tailscale.nix` — moved to features

#### Untouched

- `modules/darwin/` — macbook system modules, out of scope
- `modules/home/darwin/` — macbook HM modules, out of scope
- `modules/nixos/server/` — WIP server modules, out of scope
- `modules/options.nix` — stays as-is (gains `myConfig.colorScheme` via theming.nix)
- `hosts/macbook/` — out of scope
- `hosts/saradomin/` — out of scope (but will benefit from `presets/server.nix` later)

### Dendritic Migration Path

This refactor is a stepping stone toward the dendritic pattern:

1. **Now:** Features use `primaryUser` + `home-manager.users.${user}`. Inputs via `specialArgs`. Manual import lists.
2. **Dendritic:** Add flake-parts + import-tree. Every feature becomes a flake-parts module. Replace `specialArgs` with top-level options. Use `deferredModule` for HM/NixOS configs. import-tree auto-discovers all files — no manual imports.

The feature-per-file structure maps directly to dendritic. The migration will be about changing the plumbing (how modules receive inputs, how HM config is wired), not the organization.

### Risks

- **Color scheme breakage:** Many features depend on `config.colorScheme.palette`. If theming.nix is missing from imports, they fail. Presets mitigate this — base always includes theming.
- **HM module merge ordering:** Multiple features adding to `home-manager.users.${user}` works via NixOS module merging, but `imports` lists inside HM blocks merge too — verify nix-colors module import doesn't conflict.
- **Macbook divergence:** Macbook stays on old pattern. Future work needed to unify.
