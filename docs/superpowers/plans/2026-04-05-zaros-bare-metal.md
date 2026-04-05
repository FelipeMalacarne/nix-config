# zaros Bare Metal Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete all config changes needed for bare metal NixOS install on zaros — nvim flake input, Claude Code, nvidia, audio, and a step-by-step install guide.

**Architecture:** All changes are to the existing module tree. Each module stays focused on one concern. `hosts/zaros/default.nix` wires everything together via imports. The install guide lives in `docs/install-zaros.md` as a standalone markdown file.

**Tech Stack:** NixOS unstable, Home Manager, Hyprland + UWSM, Pipewire, nvidia open kernel module (RTX 4070 Super), Ghostty, Zsh + Starship, Neovim (flake input), Claude Code (nixpkgs)

**Spec:** `docs/superpowers/specs/2026-04-05-zaros-bare-metal-design.md`

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `flake.nix` | Modify | Add `nvim-config` flake input |
| `modules/home/common/nvim.nix` | Modify | Replace git-clone activation with flake input source |
| `modules/home/common/cli.nix` | Modify | Add `claude-code` to packages |
| `modules/nixos/gpu/nvidia.nix` | Modify | Fill RTX 4070 Super open kernel module config |
| `modules/nixos/audio.nix` | Modify | Fill pipewire + ALSA + pulse config |
| `hosts/zaros/default.nix` | Modify | Add audio + nvidia to imports list |
| `docs/install-zaros.md` | Create | Step-by-step bare metal install guide |

---

## Task 1: Add nvim-config flake input

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Add nvim-config input to flake.nix**

Open `flake.nix`. The `inputs` block currently ends before the closing `};`. Add the new input after the `noctalia` block:

```nix
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    nvim-config.url = "github:FelipeMalacarne/nvim";

  };
```

No `follows` needed — the nvim flake does not pull in nixpkgs.

- [ ] **Step 2: Verify the flake parses**

Run:
```bash
nix flake show 2>&1 | head -20
```

Expected: shows `nixosConfigurations.zaros` and `nixosConfigurations.saradomin`. If you see a parse error (not an evaluation error), fix the syntax before continuing.

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "feat: add nvim-config flake input"
```

---

## Task 2: Switch nvim.nix to flake input

**Files:**
- Modify: `modules/home/common/nvim.nix`

- [ ] **Step 1: Replace the file contents**

The current file uses a `home.activation` script that clones the repo at activation time. Replace it entirely:

```nix
# modules/home/common/nvim.nix
#
# The nvim flake input resolves to a read-only Nix store path.
# Lazy.nvim writes plugins/state to ~/.local/share/nvim and ~/.cache/nvim — unchanged.
# To update: push to the nvim repo, run `nix flake update nvim-config`, then rebuild.
{ inputs, ... }:
{
  home.file.".config/nvim".source = inputs.nvim-config;
}
```

- [ ] **Step 2: Verify the config evaluates**

Run:
```bash
nix eval .#nixosConfigurations.zaros.config.home-manager.users.felipe.home.file 2>&1 | grep nvim
```

Expected: output contains `.config/nvim` pointing to a `/nix/store/...` path. If you see `error: attribute 'nvim-config' missing`, the flake.nix from Task 1 was not saved correctly.

- [ ] **Step 3: Commit**

```bash
git add modules/home/common/nvim.nix
git commit -m "feat: switch nvim to flake input (pinned, read-only)"
```

---

## Task 3: Add claude-code to cli.nix

**Files:**
- Modify: `modules/home/common/cli.nix`

- [ ] **Step 1: Add claude-code to home.packages**

Open `modules/home/common/cli.nix`. Find the line:
```nix
  home.packages = [ pkgs.ripgrep ];
```

Replace it with:
```nix
  home.packages = with pkgs; [ ripgrep claude-code ];
```

- [ ] **Step 2: Verify the package resolves**

Run:
```bash
nix eval .#nixosConfigurations.zaros.config.home-manager.users.felipe.home.packages 2>&1 | grep claude
```

Expected: output contains a `/nix/store/...-claude-code-...` path. If you see `error: attribute 'claude-code' missing in 'pkgs'`, your nixpkgs input may not be on unstable — check `flake.nix` inputs.

- [ ] **Step 3: Commit**

```bash
git add modules/home/common/cli.nix
git commit -m "feat: add claude-code to common cli packages"
```

---

## Task 4: Fill nvidia.nix

**Files:**
- Modify: `modules/nixos/gpu/nvidia.nix`

- [ ] **Step 1: Replace the stub with the RTX 4070 Super config**

```nix
# modules/nixos/gpu/nvidia.nix
# RTX 4070 Super — open kernel module (recommended for RTX 40xx series)
{ config, ... }:
{
  # Required to load the nvidia kernel module
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/nixos/gpu/nvidia.nix
git commit -m "feat: fill nvidia module for RTX 4070 Super"
```

---

## Task 5: Fill audio.nix

**Files:**
- Modify: `modules/nixos/audio.nix`

- [ ] **Step 1: Replace the stub with pipewire config**

```nix
# modules/nixos/audio.nix
# Pipewire with ALSA + PulseAudio compatibility
{ ... }:
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/nixos/audio.nix
git commit -m "feat: fill audio module with pipewire"
```

---

## Task 6: Wire audio + nvidia into hosts/zaros/default.nix

**Files:**
- Modify: `hosts/zaros/default.nix`

- [ ] **Step 1: Add audio and nvidia to the imports list**

Open `hosts/zaros/default.nix`. Find the imports block:

```nix
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/desktop.nix
  ];
```

Replace it with:

```nix
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/gpu/nvidia.nix
    ../../modules/nixos/desktop.nix
  ];
```

- [ ] **Step 2: Do a full dry-run evaluation of the zaros config**

Run:
```bash
nix eval .#nixosConfigurations.zaros.config.system.build.toplevel 2>&1 | head -50
```

Expected: outputs a `/nix/store/...` path with no errors. Common errors and fixes:
- `error: attribute 'nvidiaPackages' missing` — the nvidia package set changed; replace `nvidiaPackages.stable` with `nvidiaPackages.latest`
- `error: The option 'hardware.graphics' does not exist` — on older nixpkgs it was `hardware.opengl`; replace with `hardware.opengl.enable = true`
- `error: attribute 'claude-code' missing` — nixpkgs channel is not unstable; check the `nixpkgs.url` in flake.nix

- [ ] **Step 3: Commit**

```bash
git add hosts/zaros/default.nix
git commit -m "feat: wire audio and nvidia modules into zaros host"
```

---

## Task 7: Write the install guide

**Files:**
- Create: `docs/install-zaros.md`

- [ ] **Step 1: Create the install guide**

```markdown
# zaros — NixOS Bare Metal Install Guide

Fresh install of NixOS on zaros (Ryzen 7 7800X3D, RTX 4070 Super).

---

## Before you start (on Arch)

1. Make sure all config changes are committed and pushed:
   ```bash
   git status   # should be clean
   git push
   ```

2. Verify the flake evaluates without errors:
   ```bash
   nix eval .#nixosConfigurations.zaros.config.system.build.toplevel
   ```
   Expected: a `/nix/store/...` path, no errors.

3. Download the NixOS minimal ISO and write it to a USB drive:
   ```bash
   # replace sdX with your USB device (check with lsblk)
   sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

---

## Boot the live USB

Boot from the USB. You will land at a shell as `nixos`.

Enable networking if needed (the minimal ISO uses NetworkManager):
```bash
sudo systemctl start NetworkManager
nmcli device wifi connect "SSID" password "password"
# or for ethernet: it should already be up
ping github.com   # verify connectivity
```

---

## Partition the disk

Identify your NVMe drive:
```bash
lsblk
```
It will be something like `/dev/nvme0n1`. Replace `nvme0n1` below with your actual device name.

```bash
sudo fdisk /dev/nvme0n1
```

Inside fdisk:
1. `g` — create a new GPT partition table
2. `n` → enter → enter → `+512M` — create 512 MiB EFI partition
3. `t` → `1` — change type to EFI System (type 1)
4. `n` → enter → enter → enter — create root partition (rest of disk)
5. `w` — write and exit

---

## Format the partitions

```bash
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2
```

---

## Mount

```bash
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot
```

---

## Generate hardware config

```bash
sudo nixos-generate-config --root /mnt
```

This writes `/mnt/etc/nixos/hardware-configuration.nix`. You need to get this file into your nix-config repo as `hosts/zaros/hardware.nix`.

```bash
# Get git on the live system
nix-shell -p git

# Clone the repo
git clone https://github.com/FelipeMalacarne/nix-config
cd nix-config

# Copy the generated hardware config
cp /mnt/etc/nixos/hardware-configuration.nix hosts/zaros/hardware.nix

# Review it — make sure the fileSystems entries match your actual partitions
cat hosts/zaros/hardware.nix

# Commit and push
git add hosts/zaros/hardware.nix
git commit -m "feat: add zaros hardware config from nixos-generate-config"
git push
```

---

## Install

```bash
sudo nixos-install --flake github:FelipeMalacarne/nix-config#zaros
```

This will take a while — it downloads and builds the full system closure.
When prompted for the root password, set something temporary (you'll use `initialPassword = "nixos"` for your user account).

---

## Reboot

```bash
sudo reboot
```

Remove the USB drive when the machine starts shutting down.

---

## First boot checklist

After logging in (SDDM autologin → Hyprland):

- [ ] Press `SUPER+Return` — Ghostty opens
- [ ] In Ghostty: `echo $SHELL` → `/run/current-system/sw/bin/zsh`
- [ ] In Ghostty: `nvim` → Neovim opens, lazy.nvim loads plugins (first run downloads them)
- [ ] In Ghostty: `claude --version` → prints Claude Code version
- [ ] In Ghostty: `eza --version` → prints version
- [ ] Check audio: `pactl info` → shows PulseAudio server (pipewire-pulse)
- [ ] Noctalia shell visible with Catppuccin Mocha theme

---

## Post-install cleanup

1. Change your password:
   ```bash
   passwd felipe
   ```

2. Remove the temporary `initialPassword` from the config. In your nix-config repo, open `hosts/zaros/default.nix` and delete this line:
   ```nix
   initialPassword = "nixos"; # temporary — change after bare metal install
   ```

3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake github:FelipeMalacarne/nix-config#zaros
   # or from a local clone:
   sudo nixos-rebuild switch --flake .#zaros
   ```

4. Commit the change:
   ```bash
   git add hosts/zaros/default.nix
   git commit -m "chore: remove initialPassword after bare metal install"
   git push
   ```
```

- [ ] **Step 2: Commit**

```bash
git add docs/install-zaros.md
git commit -m "docs: add zaros bare metal install guide"
```

---

## Task 8: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Full flake evaluation**

Run:
```bash
nix eval .#nixosConfigurations.zaros.config.system.build.toplevel
```

Expected: a single `/nix/store/...` path, no errors.

- [ ] **Step 2: Check flake structure**

Run:
```bash
nix flake show
```

Expected output includes:
```
└───nixosConfigurations
    ├───saradomin: NixOS configuration
    └───zaros: NixOS configuration
```

- [ ] **Step 3: Optional — build the VM to catch runtime issues**

Run (takes several minutes):
```bash
nix run nixpkgs#nixos-rebuild -- build-vm --flake .#zaros
./result/bin/run-zaros-vm
```

Verify Hyprland boots, Ghostty opens, `nvim` and `claude` commands are available. Nvidia will not work in the VM (LLVMPipe only) — that is expected.

- [ ] **Step 4: Tag the pre-install state**

```bash
git tag pre-bare-metal
git push origin pre-bare-metal
```

This gives you a clean rollback point if you need to reference what the config looked like before the install.
