# zaros VM Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete NixOS flake configuration for zaros that boots in a LLVMPipe QEMU VM with Hyprland, Noctalia (Catppuccin Mocha), Ghostty, and common home modules.

**Architecture:** Full module structure created upfront (stubs for deferred components). NixOS system modules handle hardware/services; Home Manager modules handle user environment. The flake wires everything together via `specialArgs = { inherit inputs; }` so every module can reach flake inputs.

**Tech Stack:** NixOS unstable, Home Manager, Hyprland + UWSM, Noctalia shell (Quickshell-based), Ghostty terminal, Zsh + Starship, Neovim (external flake input)

**Spec:** `docs/superpowers/specs/2026-03-23-zaros-vm-baseline-design.md`

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `flake.nix` | Create | Inputs + outputs wiring |
| `hosts/zaros/default.nix` | Create | Host entry point: imports, user, HM wiring, vmVariant |
| `hosts/zaros/hardware.nix` | Create | Stub — fill with nixos-generate-config at bare metal time |
| `hosts/saradomin/.gitkeep` | Create | Stub dir |
| `hosts/macbook/.gitkeep` | Create | Stub dir |
| `modules/nixos/core.nix` | Create | Locale, timezone, nix settings, flake registry |
| `modules/nixos/boot.nix` | Create | systemd-boot |
| `modules/nixos/network.nix` | Create | NetworkManager, hostname, firewall |
| `modules/nixos/desktop.nix` | Create | Hyprland+UWSM, SDDM autologin, Noctalia system deps, fonts |
| `modules/nixos/audio.nix` | Create | Stub — Phase 3 |
| `modules/nixos/gpu/nvidia.nix` | Create | Stub — Phase 3 |
| `modules/nixos/server/k3s.nix` | Create | Stub — Phase 6 |
| `modules/nixos/server/tailscale.nix` | Create | Stub — Phase 6 |
| `modules/nixos/server/services.nix` | Create | Stub — Phase 6 |
| `modules/darwin/yabai.nix` | Create | Stub — macbook later |
| `modules/darwin/skhd.nix` | Create | Stub — macbook later |
| `modules/home/common/default.nix` | Create | Imports all common modules, sets stateVersion |
| `modules/home/common/git.nix` | Create | Git identity |
| `modules/home/common/zsh.nix` | Create | Zsh + Starship |
| `modules/home/common/nvim.nix` | Create | Nvim from flake input (read-only source) |
| `modules/home/common/cli.nix` | Create | yazi, btop, fzf, ripgrep, eza, zoxide |
| `modules/home/desktop/hyprland/default.nix` | Create | Hyprland WM config |
| `modules/home/desktop/hyprland/binds.nix` | Create | Keybindings |
| `modules/home/desktop/hyprland/rules.nix` | Create | Window rules stub |
| `modules/home/desktop/hyprland/animations.nix` | Create | Animations stub |
| `modules/home/desktop/ghostty.nix` | Create | Ghostty terminal config |
| `modules/home/desktop/noctalia.nix` | Create | Noctalia shell + Catppuccin Mocha colors |
| `modules/home/darwin/yabai.nix` | Create | Stub — macbook later |
| `modules/home/darwin/skhd.nix` | Create | Stub — macbook later |
| `pkgs/default.nix` | Create | Stub — custom derivations |

---

## Task 1: flake.nix — inputs and skeleton

**Files:**
- Create: `flake.nix`

- [ ] **Step 1: Create flake.nix with all inputs and empty outputs**

```nix
# flake.nix
{
  description = "Felipe's system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia-qs must be top-level so follows overrides apply correctly
    # and only one nixpkgs version ends up in the closure
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    nvim-config.url = "github:FelipeMalacarne/nvim";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    {
      nixosConfigurations = {
        zaros = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/zaros
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };
    };
}
```

- [ ] **Step 2: Verify flake parses**

Run: `nix flake show 2>&1 | head -20`

At this point it will fail because `./hosts/zaros` doesn't exist yet — that's expected. What we're checking is that the flake.nix itself has no syntax errors. You should see a Nix evaluation error about a missing path, not a parse error.

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "feat: add flake.nix with all inputs"
```

---

## Task 2: Stub files for all deferred modules

**Files:**
- Create: all stub files listed below

- [ ] **Step 1: Create all stub directories and files**

```bash
mkdir -p hosts/saradomin hosts/macbook
mkdir -p modules/nixos/gpu modules/nixos/server
mkdir -p modules/darwin
mkdir -p modules/home/darwin
mkdir -p pkgs
touch hosts/saradomin/.gitkeep hosts/macbook/.gitkeep
```

Create `modules/nixos/audio.nix`:
```nix
# modules/nixos/audio.nix
# TODO Phase 3 — pipewire + wireplumber (fill before bare metal install on zaros)
{ }
```

Create `modules/nixos/gpu/nvidia.nix`:
```nix
# modules/nixos/gpu/nvidia.nix
# TODO Phase 3 — RTX 4070 Super open kernel module, modesetting, Wayland env vars
# Fill before bare metal install on zaros
{ }
```

Create `modules/nixos/server/k3s.nix`:
```nix
# modules/nixos/server/k3s.nix
# TODO Phase 6 — saradomin only
{ }
```

Create `modules/nixos/server/tailscale.nix`:
```nix
# modules/nixos/server/tailscale.nix
# TODO Phase 6 — saradomin only
{ }
```

Create `modules/nixos/server/services.nix`:
```nix
# modules/nixos/server/services.nix
# TODO Phase 6 — saradomin only (host-level k3s node deps)
# Note: Jellyfin, Vaultwarden, Pi-hole stay in the zamorak GitOps repo
{ }
```

Create `modules/darwin/yabai.nix`:
```nix
# modules/darwin/yabai.nix
# TODO Phase 1 — macbook only
{ }
```

Create `modules/darwin/skhd.nix`:
```nix
# modules/darwin/skhd.nix
# TODO Phase 1 — macbook only
{ }
```

Create `modules/home/darwin/yabai.nix`:
```nix
# modules/home/darwin/yabai.nix
# TODO Phase 1 — macbook only
{ }
```

Create `modules/home/darwin/skhd.nix`:
```nix
# modules/home/darwin/skhd.nix
# TODO Phase 1 — macbook only
{ }
```

Create `pkgs/default.nix`:
```nix
# pkgs/default.nix
# Custom derivations — add as needed
{ }
```

- [ ] **Step 2: Commit**

```bash
git add hosts/saradomin hosts/macbook modules/nixos/audio.nix \
  modules/nixos/gpu modules/nixos/server \
  modules/darwin modules/home/darwin pkgs
git commit -m "chore: add stub files for deferred modules"
```

---

## Task 3: NixOS core module

**Files:**
- Create: `modules/nixos/core.nix`

- [ ] **Step 1: Create core.nix**

```nix
# modules/nixos/core.nix
{ inputs, pkgs, ... }:
{
  # Locale and timezone
  i18n.defaultLocale = "pt_BR.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Pin the flake registry to the same nixpkgs used by this flake
  # so `nix run nixpkgs#foo` uses the same version as the system
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfree = true;
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/nixos/core.nix
git commit -m "feat: add nixos core module (locale, nix settings)"
```

---

## Task 4: NixOS boot module

**Files:**
- Create: `modules/nixos/boot.nix`

- [ ] **Step 1: Create boot.nix**

```nix
# modules/nixos/boot.nix
{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/nixos/boot.nix
git commit -m "feat: add nixos boot module (systemd-boot)"
```

---

## Task 5: NixOS network module

**Files:**
- Create: `modules/nixos/network.nix`

- [ ] **Step 1: Create network.nix**

```nix
# modules/nixos/network.nix
# Note: networking.networkmanager.enable is also a Noctalia system dep
# (per upstream docs) — intentionally placed here, not in desktop.nix
{ ... }:
{
  networking.hostName = "zaros";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/nixos/network.nix
git commit -m "feat: add nixos network module"
```

---

## Task 6: NixOS desktop module

**Files:**
- Create: `modules/nixos/desktop.nix`

- [ ] **Step 1: Create desktop.nix**

```nix
# modules/nixos/desktop.nix
{ pkgs, ... }:
{
  # Hyprland — withUWSM recommended since NixOS 24.11
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;

  # Display manager — SDDM with autologin
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "felipe";

  # XDG portals
  # Note: programs.hyprland.enable already adds xdg-desktop-portal-hyprland
  # Do NOT add it again via xdg.portal.extraPortals
  xdg.portal.enable = true;

  # Noctalia system dependencies
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Fonts
  # Note: nerd-fonts was split into individual packages in nixpkgs unstable (late 2024).
  # The old `nerdfonts.override { fonts = [...] }` pattern no longer works.
  # Use individual package names instead.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/nixos/desktop.nix
git commit -m "feat: add nixos desktop module (hyprland, sddm, noctalia deps)"
```

---

## Task 7: hosts/zaros — hardware stub and host entry point

**Files:**
- Create: `hosts/zaros/hardware.nix`
- Create: `hosts/zaros/default.nix`

- [ ] **Step 1: Create hardware.nix stub**

```nix
# hosts/zaros/hardware.nix
# Stub — run `nixos-generate-config` on the actual machine before Phase 3 bare metal install
# and replace this file with the generated hardware-configuration.nix
{ ... }:
{
  # Placeholder — keeps the import slot valid for VM builds
}
```

- [ ] **Step 2: Create hosts/zaros/default.nix**

```nix
# hosts/zaros/default.nix
{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/desktop.nix
  ];

  # User account
  users.users.felipe = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  # Home Manager wiring
  home-manager.useGlobalPkgs = true; # share nixpkgs with system — better cache hits
  home-manager.useUserPackages = true; # install user packages into system profile
  home-manager.users.felipe = {
    imports = [
      ../../modules/home/common
      ../../modules/home/desktop/hyprland
      ../../modules/home/desktop/ghostty.nix
      ../../modules/home/desktop/noctalia.nix
    ];
    home.username = "felipe";
    home.homeDirectory = "/home/felipe";
  };

  # VM variant — LLVMPipe software rendering for config iteration on Arch
  # Run with: nixos-rebuild build-vm --flake .#zaros && ./result/bin/run-zaros-vm
  virtualisation.vmVariant = {
    virtualisation.diskSize = 8192; # MiB — default 512 MiB too small for Hyprland + Noctalia
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-gpu-pci" # enables LLVMPipe OpenGL — required for Hyprland
      "-m 4G"
      "-smp 2"
    ];
  };

  system.stateVersion = "24.11";
}
```

- [ ] **Step 3: Verify flake evaluates**

Run: `nix flake show 2>&1 | head -30`

Expected: You should see the flake outputs tree including `nixosConfigurations.zaros`. If home modules don't exist yet you'll get an import error — that's fine, proceed to Task 8.

- [ ] **Step 4: Commit**

```bash
git add hosts/zaros/
git commit -m "feat: add hosts/zaros (default.nix + hardware stub)"
```

---

## Task 8: Common home modules

**Files:**
- Create: `modules/home/common/git.nix`
- Create: `modules/home/common/zsh.nix`
- Create: `modules/home/common/nvim.nix`
- Create: `modules/home/common/cli.nix`
- Create: `modules/home/common/default.nix`

- [ ] **Step 1: Fill in your real git email**

Before creating this file, decide what email to use (your GitHub-registered email is usually best).
The value below is a placeholder — replace it now, before committing.

- [ ] **Step 2: Create git.nix**

```nix
# modules/home/common/git.nix
{ ... }:
{
  programs.git = {
    enable = true;
    userName = "FelipeMalacarne";
    userEmail = "YOUR_EMAIL_HERE"; # replace with your real email before committing
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
```

- [ ] **Step 2: Create zsh.nix**

```nix
# modules/home/common/zsh.nix
{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
```

- [ ] **Step 3: Create nvim.nix**

```nix
# modules/home/common/nvim.nix
#
# The nvim flake input resolves to a read-only Nix store path.
# The config must NOT write into ~/.config/nvim — lazy.nvim writes
# its cache/state to ~/.local/share/nvim and ~/.cache/nvim by default,
# which is correct. Verify the upstream config does not override these paths.
{ inputs, ... }:
{
  home.file.".config/nvim".source = inputs.nvim-config;
}
```

- [ ] **Step 4: Create cli.nix**

```nix
# modules/home/common/cli.nix
{ pkgs, ... }:
{
  # ripgrep has no Home Manager module — add directly to packages
  home.packages = [ pkgs.ripgrep ];

  programs.yazi.enable = true;
  programs.btop.enable = true;
  programs.fzf.enable = true;
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
```

- [ ] **Step 5: Create default.nix**

```nix
# modules/home/common/default.nix
{ ... }:
{
  imports = [
    ./git.nix
    ./zsh.nix
    ./nvim.nix
    ./cli.nix
  ];

  # stateVersion must match or be lower than the system stateVersion
  # See: https://nix-community.github.io/home-manager/options.xhtml#opt-home.stateVersion
  home.stateVersion = "24.11";
}
```

- [ ] **Step 6: Commit**

```bash
git add modules/home/common/
git commit -m "feat: add common home modules (git, zsh, nvim, cli)"
```

---

## Task 9: Hyprland home module

**Files:**
- Create: `modules/home/desktop/hyprland/animations.nix`
- Create: `modules/home/desktop/hyprland/rules.nix`
- Create: `modules/home/desktop/hyprland/binds.nix`
- Create: `modules/home/desktop/hyprland/default.nix`

- [ ] **Step 1: Create animations.nix**

```nix
# modules/home/desktop/hyprland/animations.nix
{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    animations = {
      enabled = true;
      bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
      animation = [
        "windows, 1, 7, myBezier"
        "windowsOut, 1, 7, default, popin 80%"
        "border, 1, 10, default"
        "fade, 1, 7, default"
        "workspaces, 1, 6, default"
      ];
    };
  };
}
```

- [ ] **Step 2: Create rules.nix**

```nix
# modules/home/desktop/hyprland/rules.nix
# Minimal stub — add window rules as needed
{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      # example: "float, class:^(pavucontrol)$"
    ];
  };
}
```

- [ ] **Step 3: Create binds.nix**

```nix
# modules/home/desktop/hyprland/binds.nix
{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bind = [
      "$mod, Return, exec, uwsm app -- ghostty" # UWSM wraps apps when withUWSM = true
      "$mod, Q, killactive"
      "$mod, M, exit"
      "$mod, F, fullscreen"
      "$mod, V, togglefloating"

      # App launcher — requires a launcher installed (e.g. rofi, fuzzel, or Noctalia's built-in)
      # Noctalia may provide its own launcher — check its docs and update this bind accordingly
      "$mod, Space, exec, uwsm app -- fuzzel"

      # Focus movement
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"

      # Workspace switching
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"

      # Move window to workspace
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
    ];

    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };
}
```

- [ ] **Step 4: Create hyprland/default.nix**

```nix
# modules/home/desktop/hyprland/default.nix
#
# UWSM note: programs.hyprland.withUWSM = true is set at the NixOS level.
# Apps launched from Hyprland should use `uwsm app -- <appname>` in exec-once
# and keybinds. See: https://wiki.hyprland.org/Useful-Utilities/Systemd-start/
{ ... }:
{
  imports = [
    ./binds.nix
    ./rules.nix
    ./animations.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = ",preferred,auto,1"; # auto-detect monitor

      exec-once = [
        "uwsm app -- ghostty" # spawn a terminal on start
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(cba6f7ff)"; # Catppuccin Mocha mauve
        "col.inactive_border" = "rgba(6c7086ff)"; # Catppuccin Mocha overlay0
        layout = "dwindle";
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      input = {
        kb_layout = "br"; # Brazilian ABNT2 keyboard
        follow_mouse = 1;
        touchpad.natural_scroll = false;
      };

      misc = {
        force_default_wallpaper = 0; # disable Hyprland anime wallpaper
        disable_hyprland_logo = true;
      };
    };
  };
}
```

- [ ] **Step 5: Commit**

```bash
git add modules/home/desktop/hyprland/
git commit -m "feat: add hyprland home module with UWSM binds"
```

---

## Task 10: Ghostty home module

**Files:**
- Create: `modules/home/desktop/ghostty.nix`

- [ ] **Step 1: Create ghostty.nix**

```nix
# modules/home/desktop/ghostty.nix
{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 13;
      shell-integration = "zsh";
      window-decoration = false; # Hyprland handles decorations
      background-opacity = 0.95;

      # Catppuccin Mocha — basic colors to match Noctalia theme
      background = "1e1e2e";
      foreground = "cdd6f4";
      cursor-color = "f5e0dc";
      selection-background = "313244";
      selection-foreground = "cdd6f4";
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/home/desktop/ghostty.nix
git commit -m "feat: add ghostty home module"
```

---

## Task 11: Noctalia home module with Catppuccin Mocha

**Files:**
- Create: `modules/home/desktop/noctalia.nix`

- [ ] **Step 1: Verify the Noctalia flake's actual homeModules attribute name**

Run: `nix flake show github:noctalia-dev/noctalia-shell 2>&1 | grep -i home`

Look for the attribute name under `homeModules` or `homeManagerModules`. Common possibilities:
- `homeModules.default`
- `homeModules.noctalia`
- `homeManagerModules.default`

Use whatever the output shows. The code below assumes `homeModules.default` — update if different.

- [ ] **Step 2: Check Noctalia's color token option names**

Run: `nix eval github:noctalia-dev/noctalia-shell#homeModules.default --apply builtins.attrNames 2>&1 | head -30`

Or check the settings reference at: https://github.com/noctalia-dev/noctalia-shell/blob/main/Assets/settings-default.json

This tells you what `programs.noctalia-shell.colors` keys are valid.

- [ ] **Step 3: Create noctalia.nix**

```nix
# modules/home/desktop/noctalia.nix
#
# Catppuccin Mocha palette mapped to Material 3 color tokens.
# Palette reference: https://github.com/catppuccin/catppuccin#-palette
#
# IMPORTANT: Verify the homeModules attribute name before applying:
#   nix flake show github:noctalia-dev/noctalia-shell
# Update the import below if it differs from homeModules.default
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;

    colors = {
      # === Surface / Background colors ===
      # base: main background
      # surface: slightly elevated surfaces (cards, containers)
      # surface-variant: alternative surface
      base = "#1e1e2e"; # Catppuccin Mocha base
      surface = "#313244"; # Catppuccin Mocha surface0
      "surface-variant" = "#45475a"; # Catppuccin Mocha surface1

      # === Accent colors (Material 3 roles) ===
      primary = "#cba6f7"; # mauve — main brand color
      "on-primary" = "#1e1e2e"; # text on primary
      "primary-container" = "#45475a"; # surface1 — container for primary
      "on-primary-container" = "#cba6f7"; # primary text in container

      secondary = "#89b4fa"; # blue
      "on-secondary" = "#1e1e2e";
      "secondary-container" = "#313244";
      "on-secondary-container" = "#89b4fa";

      tertiary = "#a6e3a1"; # green
      "on-tertiary" = "#1e1e2e";
      "tertiary-container" = "#313244";
      "on-tertiary-container" = "#a6e3a1";

      error = "#f38ba8"; # red
      "on-error" = "#1e1e2e";
      "error-container" = "#45475a";
      "on-error-container" = "#f38ba8";

      # === Text / On-surface colors ===
      "on-surface" = "#cdd6f4"; # Catppuccin Mocha text
      "on-surface-variant" = "#bac2de"; # subtext1

      # === Outline / Border colors ===
      outline = "#6c7086"; # overlay0
      "outline-variant" = "#45475a"; # surface1

      # === Background ===
      background = "#1e1e2e";
      "on-background" = "#cdd6f4";

      # === Inverse colors (for snackbars, tooltips) ===
      "inverse-surface" = "#cdd6f4";
      "inverse-on-surface" = "#1e1e2e";
      "inverse-primary" = "#6c3483"; # darker mauve
    };
  };
}
```

- [ ] **Step 4: Commit**

```bash
git add modules/home/desktop/noctalia.nix
git commit -m "feat: add noctalia home module with catppuccin mocha colors"
```

---

## Task 12: Verify full flake evaluation

**Files:** none (verification only)

- [ ] **Step 1: Check flake structure**

Run: `nix flake show`

Expected output should include:
```
└───nixosConfigurations
    └───zaros: NixOS configuration
```

If you see errors about missing modules or unknown options, fix those before proceeding.

- [ ] **Step 2: Dry-run evaluation of the zaros config**

Run: `nix eval .#nixosConfigurations.zaros.config.system.build.toplevel 2>&1 | head -50`

This evaluates the full NixOS configuration without building. Any Nix option errors (unknown options, type mismatches) surface here.

Common issues and fixes:
- `error: attribute 'noctalia' missing` → the noctalia homeModules attribute name is wrong. Re-run `nix flake show github:noctalia-dev/noctalia-shell` and update the import in `noctalia.nix`.
- `error: The option ... does not exist` → check the option name against the HM or NixOS module docs.
- `error: cannot coerce a set to a string` → likely a missing `pkgs.` prefix somewhere.

- [ ] **Step 3: Commit any fixes**

```bash
git add <the specific files you changed>
git commit -m "fix: resolve nix evaluation errors"
```

---

## Task 13: Build VM and smoke test

**Files:** none (build + runtime verification)

- [ ] **Step 1: Build the VM image**

Run (from the repo root on your Arch machine with nix installed):
```bash
nixos-rebuild build-vm --flake .#zaros
```

Expected: build completes, `result/bin/run-zaros-vm` symlink appears.

If the build fails with a hash mismatch on `nvim-config`, run `nix flake update nvim-config` to fetch the current lock.

- [ ] **Step 2: Run the VM**

```bash
./result/bin/run-zaros-vm
```

The VM will be slow (LLVMPipe software rendering). Allow 60-120 seconds for first boot.

- [ ] **Step 3: Smoke test checklist**

In the VM, verify:
- [ ] SDDM autologin completes — lands directly in Hyprland (no password prompt)
- [ ] Hyprland desktop is visible (no black screen, no crash)
- [ ] Press `SUPER+Return` — Ghostty opens
- [ ] In Ghostty: `echo $SHELL` → `/run/current-system/sw/bin/zsh`
- [ ] In Ghostty: `starship --version` → prints version
- [ ] In Ghostty: `nvim` → Neovim opens (lazy.nvim may download plugins on first run)
- [ ] In Ghostty: `eza --version` → prints version
- [ ] In Ghostty: `zoxide --version` → prints version
- [ ] Noctalia shell is visible (panel/bar rendered with Catppuccin Mocha colors)
- [ ] Press `SUPER+M` → exits Hyprland cleanly

- [ ] **Step 4: Commit final state**

```bash
git add -A
git commit -m "feat: zaros VM baseline working (hyprland + noctalia + ghostty)"
```

---

## Notes for the implementer

**Nix on Arch:** Install nix with the Determinate Systems installer for best flake support:
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**nixos-rebuild on non-NixOS:** You need `nixos-rebuild` available. It's in `nixpkgs#nixos-rebuild`. Run it with:
```bash
nix run nixpkgs#nixos-rebuild -- build-vm --flake .#zaros
```

**Noctalia color option keys:** The `colors` attrset keys depend on what Noctalia's HM module exposes. If the module uses different key names than the ones in `noctalia.nix`, you'll get `unknown option` errors. Inspect the module options with:
```bash
nix eval github:noctalia-dev/noctalia-shell --apply 'x: builtins.attrNames x.homeModules'
```

**Keyboard layout:** `kb_layout = "br"` in `hyprland/default.nix` sets Brazilian ABNT2. Change to `"us"` for US layout inside the VM if needed.

**VM performance:** LLVMPipe is CPU-only rendering. Expect 1-5 FPS in heavy animations. This is normal — the goal is config correctness, not performance. Disable animations in `animations.nix` if they make the VM unusable.
