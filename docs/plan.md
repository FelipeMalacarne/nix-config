# nix-config — Project Plan & Context

## Overview

Full declarative system configuration across 3 machines using NixOS + nix-darwin + Home Manager.
Goal: consistent tooling, theming, and workflow on every machine from a single repository.

---

## Machines

| Hostname | OS (current → target) | Hardware | Role |
|---|---|---|---|
| `zaros` | Arch Linux (Omarchy) → NixOS | Ryzen 7 7800X3D, RTX 4070 Super | Main desktop |
| `saradomin` | Debian → NixOS | Intel N97 (iGPU), mini PC | Home server (k3s) |
| `macbook` | macOS → nix-darwin | Apple M3 | Work laptop |

**Important:** Ryzen 7800X3D has **no iGPU**. GPU passthrough to VM is not viable without a secondary GPU. Use LLVMPipe VM for config development.

---

## Stack

| Layer | Tool | Notes |
|---|---|---|
| OS (zaros + saradomin) | NixOS unstable | Requires unstable for Noctalia/Quickshell |
| OS (macbook) | nix-darwin | |
| Window Manager | Hyprland + UWSM | UWSM recommended since NixOS 24.11 |
| Desktop Shell | Noctalia | Via flake, first-class HM module |
| Theming | Noctalia colors (Catppuccin Mocha) | Material 3 tokens, user-templates for other apps |
| Terminal | Ghostty | Wayland-native, macOS first-class, same on all machines |
| Editor | Neovim | Separate repo, referenced as flake input |
| Shell | Zsh + Starship | Consistent across all 3 machines, POSIX compatible, zsh already used on macbook |
| macOS WM | yabai + skhd | |
| Server stack | k3s, Tailscale, Jellyfin, Vaultwarden, Pi-hole | saradomin only |

---

## Neovim Config

- Lives in a **separate GitHub repo**: `github.com/FelipeMalacarne/nvim-config` (or similar)
- Referenced as a flake input in `nix-config`, **not merged** into this repo
- Reason: used independently on Arch now; should stay portable outside NixOS
- In Home Manager: `home.file.".config/nvim".source = inputs.nvim-config;`

---

## Shell (Zsh)

Zsh chosen over Fish for POSIX compatibility and existing muscle memory on macbook. Home Manager handles plugins declaratively — no plugin manager needed.

```nix
# modules/home/common/zsh.nix
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

---

## saradomin — k3s architecture note

NixOS manages the **host/node only**. Application workloads stay in the existing `zamorak` GitOps repo managed by ArgoCD — nothing moves into nix-config.

- NixOS owns: k3s service, Tailscale, firewall, node-level dependencies
- ArgoCD/zamorak owns: Jellyfin, Vaultwarden, Pi-hole, all k8s manifests

This is the correct separation of concerns. Do not migrate workloads into NixOS services.

---



Noctalia has **first-class NixOS + Home Manager support** via its own flake.

```nix
# flake.nix inputs
noctalia = {
  url = "github:noctalia-dev/noctalia-shell";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.noctalia-qs.follows = "noctalia-qs";
};
noctalia-qs = {
  url = "github:noctalia-dev/noctalia-qs";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# home-manager usage
imports = [ inputs.noctalia.homeModules.default ];
programs.noctalia-shell = {
  enable = true;
  settings = { ... };
  colors = { ... }; # Catppuccin Mocha Material 3 tokens
  plugins = { ... };
};
```

- Requires `nixpkgs-unstable` (Quickshell dependency)
- Replaces: waybar, mako/dunst, swaylock/hyprlock, hypridle, rofi, swww
- `user-templates` feature propagates colorscheme to apps outside Noctalia (Ghostty, GTK, etc.)
- Docs: https://docs.noctalia.dev/getting-started/nixos/
- NixOS system deps needed: `networking.networkmanager.enable`, `hardware.bluetooth.enable`, `services.power-profiles-daemon.enable`, `services.upower.enable`

---

## Repository Structure

```
nix-config/
├── flake.nix
├── flake.lock
│
├── hosts/
│   ├── zaros/
│   │   ├── default.nix             # imports hardware + nixos modules
│   │   └── hardware.nix            # nixos-generate-config output
│   ├── saradomin/
│   │   ├── default.nix
│   │   └── hardware.nix
│   └── macbook/
│       └── default.nix
│
├── modules/
│   ├── nixos/
│   │   ├── core.nix                # locale (pt_BR), timezone (America/Sao_Paulo), fonts, nix settings, flake registry
│   │   ├── boot.nix                # systemd-boot, kernel params
│   │   ├── network.nix             # networkmanager, firewall, bluetooth
│   │   ├── audio.nix               # pipewire + wireplumber
│   │   ├── gpu/
│   │   │   └── nvidia.nix          # open kernel module (RTX 40xx), modesetting, wayland env vars
│   │   ├── desktop.nix             # hyprland, UWSM, SDDM, xdg portals, noctalia system deps
│   │   └── server/
│   │       ├── k3s.nix
│   │       ├── tailscale.nix
│   │       └── services.nix        # jellyfin, vaultwarden, pihole
│   │
│   ├── darwin/
│   │   ├── core.nix                # homebrew, system defaults
│   │   ├── yabai.nix
│   │   └── skhd.nix
│   │
│   └── home/
│       ├── common/                 # ALL hosts
│       │   ├── default.nix         # imports everything in common/
│       │   ├── git.nix
│       │   ├── zsh.nix              # zsh + starship
│       │   ├── nvim.nix            # home.file pointing to nvim flake input
│       │   └── cli.nix             # yazi, btop, fzf, ripgrep, eza, zoxide
│       │
│       ├── desktop/                # graphical hosts (zaros + macbook)
│       │   ├── hyprland/           # zaros only
│       │   │   ├── default.nix     # wayland.windowManager.hyprland
│       │   │   ├── binds.nix
│       │   │   ├── rules.nix
│       │   │   └── animations.nix
│       │   ├── noctalia.nix        # programs.noctalia-shell full config
│       │   ├── ghostty.nix         # programs.ghostty
│       │   └── apps.nix            # browser, yazi GUI, etc.
│       │
│       └── darwin/
│           ├── yabai.nix
│           └── skhd.nix
│
└── pkgs/
    └── default.nix                 # custom derivations if needed
```

---

## flake.nix

```nix
{
  description = "Felipe's system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-config.url = "github:FelipeMalacarne/nvim-config";
  };

  outputs = { nixpkgs, nix-darwin, home-manager, ... } @ inputs: {

    nixosConfigurations = {
      zaros = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/zaros
          home-manager.nixosModules.home-manager
          { home-manager.extraSpecialArgs = { inherit inputs; }; }
        ];
      };

      saradomin = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/saradomin
          home-manager.nixosModules.home-manager
          { home-manager.extraSpecialArgs = { inherit inputs; }; }
        ];
      };
    };

    darwinConfigurations = {
      macbook = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/macbook
          home-manager.darwinModules.home-manager
          { home-manager.extraSpecialArgs = { inherit inputs; }; }
        ];
      };
    };
  };
}
```

---

## What each host imports

### zaros (main desktop)
**NixOS modules:** `core` `boot` `network` `audio` `gpu/nvidia` `desktop`
**Home modules:** `common/*` + `desktop/hyprland/*` + `desktop/noctalia` + `desktop/ghostty` + `desktop/apps`

### saradomin (headless server)
**NixOS modules:** `core` `boot` `network` `server/*`
**Home modules:** `common/*` only (zsh, nvim, cli — useful over SSH)
**No display manager, no Hyprland, no audio**

### macbook (work laptop)
**Darwin modules:** `core` `yabai` `skhd`
**Home modules:** `common/*` + `desktop/ghostty` + `desktop/apps` + `darwin/*`

---

## Nvidia (zaros) — important details

RTX 4070 Super on NixOS requires:

```nix
# modules/nixos/gpu/nvidia.nix
hardware.nvidia = {
  modesetting.enable = true;
  open = true;          # open source kernel module, recommended for RTX 40xx
  nvidiaSettings = true;
};
hardware.graphics.enable = true;

# Wayland/Hyprland env vars
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  GBM_BACKEND = "nvidia-drm";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  WLR_NO_HARDWARE_CURSORS = "1";
};
```

---

## VM Development Workflow

For iterating on the config before going bare metal on zaros:

```bash
# Build and run VM (from your Arch machine with nix installed)
nixos-rebuild build-vm --flake .#zaros
./result/bin/run-zaros-vm
```

Required in zaros host config for Hyprland to work in VM:

```nix
virtualisation.vmVariant = {
  virtualisation.qemu.options = [
    "-vga none"
    "-device virtio-gpu-pci"   # enables LLVMPipe OpenGL — required for Hyprland
    "-m 4G"
    "-smp 2"
  ];
};
```

Performance will be slow (CPU software rendering) but sufficient for config iteration.

---

## Build Phases

> **Starting with macbook** — lower risk, no wipe needed, rebuilds Nix intuition before Linux hosts.

### Phase 1 — macbook bootstrap
- Create new macOS user
- Install nix (Determinate Systems installer)
- Bootstrap nix-darwin with minimal `macbook` host
- Wire common home modules: zsh, starship, nvim, CLI tools
- Add yabai + skhd

### Phase 2 — VM baseline (zaros)
- Minimal zaros config: Hyprland + Ghostty + autologin
- Run VM on zaros (Arch) with nix installed + LLVMPipe QEMU
- Prove flake structure boots in VM
- No theming yet

### Phase 3 — zaros system foundation
- Fill nvidia, audio, pipewire, network, boot modules
- End of phase: install bare metal on zaros

### Phase 4 — Noctalia + theming
- Wire Noctalia HM module
- Define Catppuccin Mocha as Material 3 color tokens in `noctalia.nix`
- Set up user-templates for Ghostty + GTK

### Phase 5 — common home modules
- Zsh, Starship, nvim flake input, CLI tools
- Works identically on all 3 machines from here

### Phase 6 — saradomin
- Install NixOS on N97
- Migrate k3s node from Debian declaratively
- Workloads (Jellyfin, Vaultwarden, Pi-hole) stay in `zamorak` GitOps repo — unchanged

---

## Useful References

- Noctalia NixOS docs: https://docs.noctalia.dev/getting-started/nixos/
- Noctalia Hyprland compositor settings: https://docs.noctalia.dev/getting-started/compositor-settings/hyprland/
- Noctalia config defaults (full settings reference): https://github.com/noctalia-dev/noctalia-shell/blob/main/Assets/settings-default.json
- Hyprland NixOS wiki: https://wiki.nixos.org/wiki/Hyprland
- Home Manager options: https://nix-community.github.io/home-manager/options.xhtml
- nix-darwin: https://github.com/LnL7/nix-darwin

---

## Felipe's GitHub

`github.com/FelipeMalacarne` — nvim config repo lives here, reference it as flake input.
