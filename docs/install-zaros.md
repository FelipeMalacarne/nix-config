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
   nix flake show
   ```
   Expected: shows nixosConfigurations.zaros and nixosConfigurations.saradomin.

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
