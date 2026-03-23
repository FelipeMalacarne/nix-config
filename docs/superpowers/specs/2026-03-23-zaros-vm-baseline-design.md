# zaros VM Baseline — Design Spec

**Date:** 2026-03-23
**Branch:** restructure
**Goal:** Bootstrap the full nix-config repository structure and get a working NixOS system booting in a VM on zaros (Arch + LLVMPipe QEMU), with Hyprland, Noctalia (Catppuccin Mocha), Ghostty, and common home modules including the nvim flake input.

---

## Scope

This spec covers Phase 2 + Phase 4 of the project plan, combined:
- Full repository directory structure (approach A — all directories created upfront)
- zaros host only (macbook and saradomin added later)
- VM-ready config with LLVMPipe QEMU vmVariant
- Noctalia with Catppuccin Mocha from day one (skipping the "no theming yet" interim)
- Common home modules wired for all future hosts

Out of scope: nvidia GPU module, saradomin server modules, darwin modules (stubs only).

---

## flake.nix

**Inputs — exact wiring:**
```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

home-manager.url = "github:nix-community/home-manager";
home-manager.inputs.nixpkgs.follows = "nixpkgs";

noctalia-qs.url = "github:noctalia-dev/noctalia-qs";
noctalia-qs.inputs.nixpkgs.follows = "nixpkgs";

noctalia.url = "github:noctalia-dev/noctalia-shell";
noctalia.inputs.nixpkgs.follows = "nixpkgs";
noctalia.inputs.noctalia-qs.follows = "noctalia-qs";

nvim-config.url = "github:FelipeMalacarne/nvim";
```

`noctalia-qs` must be a top-level input so its `follows` overrides are applied correctly and only one nixpkgs version ends up in the closure.

**Outputs:** `nixosConfigurations.zaros` only. Darwin and saradomin added later.

`specialArgs = { inherit inputs; }` on both NixOS and home-manager so every module can access flake inputs (required for nvim-config source and noctalia homeModules).

---

## hosts/zaros/

### `default.nix`
- Imports: `./hardware.nix`, `../../modules/nixos/core.nix`, `../../modules/nixos/boot.nix`, `../../modules/nixos/network.nix`, `../../modules/nixos/desktop.nix`
- Defines user `felipe` with `isNormalUser = true`, standard groups (`wheel`, `networkmanager`, `video`, `audio`)
- Sets HM identity and global package options:
  ```nix
  home-manager.useGlobalPkgs = true;     # share nixpkgs with system — better cache hits
  home-manager.useUserPackages = true;   # install user packages into system profile
  home-manager.users.felipe.home.username = "felipe";
  home-manager.users.felipe.home.homeDirectory = "/home/felipe";
  ```
- Wires home-manager: `home-manager.users.felipe` imports `../../modules/home/common` + `../../modules/home/desktop/hyprland` + `../../modules/home/desktop/ghostty.nix` + `../../modules/home/desktop/noctalia.nix`
- Includes `vmVariant` block for LLVMPipe QEMU:
  ```nix
  virtualisation.vmVariant = {
    virtualisation.diskSize = 8192; # MiB — default 512 MiB is too small for Hyprland + Noctalia
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-gpu-pci"
      "-m 4G"
      "-smp 2"
    ];
  };
  ```

### `hardware.nix`
- Stub only — comment instructs running `nixos-generate-config` on bare metal before Phase 3 install
- Imported by `default.nix` so the slot exists

---

## NixOS Modules (`modules/nixos/`)

### `core.nix`
- `i18n.defaultLocale = "pt_BR.UTF-8"`
- `time.timeZone = "America/Sao_Paulo"`
- `nix.settings.experimental-features = [ "nix-command" "flakes" ]`
- `nix.registry.nixpkgs.flake = inputs.nixpkgs` (pins flake registry)
- `nixpkgs.config.allowUnfree = true`

### `boot.nix`
- `boot.loader.systemd-boot.enable = true`
- `boot.loader.efi.canTouchEfiVariables = true`

### `network.nix`
- `networking.hostName = "zaros"`
- `networking.networkmanager.enable = true`
- `networking.firewall.enable = true`

### `desktop.nix`
- Hyprland: `programs.hyprland.enable = true`, `programs.hyprland.withUWSM = true`
- SDDM + autologin — use NixOS display manager abstraction:
  ```nix
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "felipe";
  ```
- XDG portals: `xdg.portal.enable = true`. Note: `programs.hyprland.enable` automatically adds `xdg-desktop-portal-hyprland` — do not add it again via `xdg.portal.extraPortals` to avoid duplication.
- Noctalia system deps: `hardware.bluetooth.enable = true`, `services.power-profiles-daemon.enable = true`, `services.upower.enable = true`
  - `networking.networkmanager.enable` is also a Noctalia dep per upstream docs but is intentionally placed in `network.nix`, not here.
- Font packages: noto-fonts, nerd-fonts (for shell/editor)

### `gpu/nvidia.nix`
- Empty stub with comment: "Fill before bare metal install on zaros (Phase 3)"

### `server/` directory
- Empty stubs: `k3s.nix`, `tailscale.nix`, `services.nix` — for saradomin (Phase 6)

---

## Home Modules (`modules/home/`)

### `common/default.nix`
Imports all common modules:
- `./git.nix`
- `./zsh.nix`
- `./nvim.nix`
- `./cli.nix`

Sets `home.stateVersion`. Does NOT set `home.username` or `home.homeDirectory` — those are set per-host in `hosts/zaros/default.nix`.

### `common/git.nix`
- `programs.git.enable = true`
- `programs.git.userName = "FelipeMalacarne"`
- `programs.git.userEmail` (placeholder, easy to update)

### `common/zsh.nix`
- `programs.zsh.enable = true`
- `programs.zsh.autosuggestion.enable = true`
- `programs.zsh.syntaxHighlighting.enable = true`
- `programs.zsh.enableCompletion = true`
- `programs.starship.enable = true`, `programs.starship.enableZshIntegration = true`

### `common/nvim.nix`
- `home.file.".config/nvim".source = inputs.nvim-config;`
- **Constraint:** The store path is read-only and immutable. The nvim config must write caches/state to `~/.local/share/nvim` or `~/.cache/nvim` (standard lazy.nvim behavior), never into `~/.config/nvim` itself. This is the default for lazy.nvim — verify the upstream config does not override these paths.

### `common/cli.nix`
- `programs.yazi.enable = true`
- `programs.btop.enable = true`
- `programs.fzf.enable = true`
- `home.packages = [ pkgs.ripgrep ]` — ripgrep has no HM module, add directly to packages
- `programs.eza.enable = true`
- `programs.zoxide.enable = true`

### `desktop/hyprland/default.nix`
- `wayland.windowManager.hyprland.enable = true`
- `wayland.windowManager.hyprland.settings` with minimal monitor, exec-once, general config
- Imports `./binds.nix`, `./rules.nix`, `./animations.nix`
- **UWSM note:** With `programs.hyprland.withUWSM = true` set at the NixOS level, apps launched from Hyprland should be wrapped: `exec-once = uwsm app -- ghostty`. Verify against the [Hyprland UWSM docs](https://wiki.hyprland.org/Useful-Utilities/Systemd-start/) at implementation time.

### `desktop/hyprland/binds.nix`
Minimal keybinds: super+return → ghostty, super+Q → close, super+M → exit, super+space → launcher.

### `desktop/hyprland/rules.nix`
Minimal window rules stub.

### `desktop/hyprland/animations.nix`
Minimal animations — default Hyprland animations, easily replaced by Noctalia later.

### `desktop/ghostty.nix`
- `programs.ghostty.enable = true`
- Minimal settings: font size, shell = zsh

### `desktop/noctalia.nix`
- `imports = [ inputs.noctalia.homeModules.default ]`
  - **Note:** Verify the actual attribute name against the upstream flake before implementing (`nix flake show github:noctalia-dev/noctalia-shell`). It may be `homeModules.noctalia` or `homeManagerModules.default` rather than `homeModules.default`.
- `programs.noctalia-shell.enable = true`
- Full Catppuccin Mocha Material 3 color token mapping:
  - Surface colors: `base (#1e1e2e)`, `surface (#313244)`, `surface-variant (#45475a)`
  - Primary: `#cba6f7` (mauve)
  - Secondary: `#89b4fa` (blue)
  - Tertiary: `#a6e3a1` (green)
  - Error: `#f38ba8` (red)
  - On-colors derived from Catppuccin text tokens

### `darwin/` directory
- Empty stubs: `yabai.nix`, `skhd.nix` — for macbook (Phase 1, later)

---

## Directory Structure (final)

```
nix-config/
├── flake.nix
├── flake.lock
├── docs/
│   └── plan.md
├── hosts/
│   ├── zaros/
│   │   ├── default.nix
│   │   └── hardware.nix
│   ├── saradomin/          # stub dirs
│   └── macbook/            # stub dirs
├── modules/
│   ├── nixos/
│   │   ├── core.nix
│   │   ├── boot.nix
│   │   ├── network.nix
│   │   ├── desktop.nix
│   │   ├── audio.nix       # stub — Phase 3
│   │   ├── gpu/
│   │   │   └── nvidia.nix  # stub
│   │   └── server/
│   │       ├── k3s.nix     # stub
│   │       ├── tailscale.nix # stub
│   │       └── services.nix  # stub
│   ├── darwin/
│   │   ├── yabai.nix       # stub
│   │   └── skhd.nix        # stub
│   └── home/
│       ├── common/
│       │   ├── default.nix
│       │   ├── git.nix
│       │   ├── zsh.nix
│       │   ├── nvim.nix
│       │   └── cli.nix
│       ├── desktop/
│       │   ├── hyprland/
│       │   │   ├── default.nix
│       │   │   ├── binds.nix
│       │   │   ├── rules.nix
│       │   │   └── animations.nix
│       │   ├── ghostty.nix
│       │   └── noctalia.nix
│       └── darwin/
│           ├── yabai.nix   # stub
│           └── skhd.nix    # stub
└── pkgs/
    └── default.nix         # stub
```

---

## VM Testing Workflow

```bash
# From zaros (Arch) with nix installed
nixos-rebuild build-vm --flake .#zaros
./result/bin/run-zaros-vm
```

Expected result: VM boots → SDDM autologins as `felipe` → Hyprland starts → Noctalia shell loads with Catppuccin Mocha theme → Ghostty available.

---

## What's explicitly deferred

| Item | Phase |
|---|---|
| nvidia.nix (RTX 4070 Super) | Phase 3 — bare metal zaros |
| audio.nix (pipewire + wireplumber) | Phase 3 — bare metal zaros |
| macbook / nix-darwin | Phase 1 — later |
| saradomin / k3s | Phase 6 |
| Noctalia user-templates (GTK, etc.) | After Phase 4 baseline |
