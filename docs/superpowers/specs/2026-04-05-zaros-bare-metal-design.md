# zaros Bare Metal Install — Design Spec

**Date:** 2026-04-05
**Branch:** restructure
**Goal:** Complete Phase 3 — fill all stubs (nvidia, audio), add Claude Code and nvim flake input, and produce a step-by-step install guide so the first boot on bare metal zaros lands in a fully working system.

---

## Scope

This spec covers the config changes needed before the bare metal NixOS install on zaros, and the installation guide that goes with it.

**In scope:**
- Fill `gpu/nvidia.nix` stub (RTX 4070 Super, open kernel module)
- Fill `audio.nix` stub (pipewire)
- Wire nvidia + audio into `hosts/zaros/default.nix` imports
- Add `nvim-config` flake input; replace git-clone activation with flake input (read-only, pinned)
- Add `claude-code` package declaratively via nixpkgs
- Write `docs/install-zaros.md` — step-by-step install guide (partition, format, hardware.nix, flake install, first boot checklist)

**Out of scope:**
- Noctalia user-templates (GTK, cursor theme) — post-install polish
- saradomin / macbook — separate phases
- btrfs — ext4 chosen for simplicity; NixOS generation rollback covers recovery

---

## flake.nix

Add `nvim-config` as a top-level input:

```nix
nvim-config.url = "github:FelipeMalacarne/nvim";
```

No `follows` needed — the nvim flake doesn't pull in nixpkgs as a dependency.

---

## modules/home/common/nvim.nix

Replace the git-clone activation script with a flake input source:

```nix
{ inputs, ... }:
{
  home.file.".config/nvim".source = inputs.nvim-config;
}
```

The store path is read-only. Lazy.nvim writes plugins/state to `~/.local/share/nvim` and `~/.cache/nvim` by default — this is correct and unchanged. To update the nvim config: push to the `nvim` repo, run `nix flake update nvim-config`, then `nixos-rebuild switch`.

---

## modules/home/common/cli.nix

Add `claude-code` to packages (`pkgs.claude-code` is in nixpkgs unstable at 2.1.92):

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [ ripgrep claude-code ];
  # ... rest unchanged
}
```

---

## modules/nixos/gpu/nvidia.nix

RTX 4070 Super — open kernel module (recommended for RTX 40xx series):

```nix
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

---

## modules/nixos/audio.nix

Pipewire with ALSA + PulseAudio compatibility:

```nix
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

---

## hosts/zaros/default.nix

Add nvidia and audio to the imports list:

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

No other changes to this file.

---

## hosts/zaros/hardware.nix

This file is generated on the live USB during install — it is not written in advance.

**Workflow:** Boot NixOS ISO → partition → mount → `nixos-generate-config --root /mnt` → copy `/mnt/etc/nixos/hardware-configuration.nix` into the repo as `hosts/zaros/hardware.nix` → commit + push → `nixos-install`.

The current stub (placeholder `fileSystems."/"`) is sufficient for VM builds and is replaced at install time.

---

## Disk Layout

GPT partition table, ext4 root. NixOS boot generation rollback (systemd-boot) covers recovery — btrfs not needed.

| Partition | Size | Type | Filesystem | Mount |
|---|---|---|---|---|
| 1 | 512 MiB | EFI System | FAT32 | `/boot` |
| 2 | remainder | Linux filesystem | ext4, label `nixos` | `/` |

---

## docs/install-zaros.md

A step-by-step guide committed to the repo covering:

1. **Pre-install (on Arch):** ensure all config changes are committed and `nix flake check` passes
2. **Boot live USB:** boot NixOS minimal ISO
3. **Partition:** `fdisk /dev/nvme0n1` — GPT, EFI + root
4. **Format:** `mkfs.fat -F 32 -n boot /dev/nvme0n1p1` + `mkfs.ext4 -L nixos /dev/nvme0n1p2`
5. **Mount:** `mount /dev/disk/by-label/nixos /mnt` + `mkdir /mnt/boot` + `mount /dev/nvme0n1p1 /mnt/boot`
6. **Generate hardware config:** `nixos-generate-config --root /mnt`
7. **Update repo:** on the live USB, run `nix-shell -p git` to get git, then `git clone https://github.com/FelipeMalacarne/nix-config`, copy `/mnt/etc/nixos/hardware-configuration.nix` into `hosts/zaros/hardware.nix`, commit, push
8. **Install:** `nixos-install --flake github:FelipeMalacarne/nix-config#zaros`
9. **Reboot**
10. **First boot checklist:** change password, verify Hyprland + Ghostty + nvim + claude-code
11. **Post-install:** remove `initialPassword` from `hosts/zaros/default.nix`, `nixos-rebuild switch`

---

## What's deferred

| Item | When |
|---|---|
| Noctalia user-templates (GTK, cursor) | Post-install polish |
| macbook / nix-darwin | Phase 1 — separate |
| saradomin / k3s | Phase 6 — separate |
