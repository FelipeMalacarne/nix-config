# NixOS Configuration

Felipe's system configuration repo. Uses flake-parts, home-manager, stylix, nix-darwin.

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

## Key Services (for reference)
- Sunshine (game streaming server) → runs on **zaros** only (needs NVENC)
- Games and GPU-accelerated workloads → **zaros** only

## Module System

### Auto-import (import-tree)
All `.nix` files under `modules/` are auto-discovered via `import-tree`, **excluding** paths matching `.*/config/.*` (e.g., nvim config). A new `modules/features/foo.nix` is automatically discovered — no manual import registration needed at the flake level.

### Module Registration Pattern
Each feature module must register itself. Two patterns:

**Cross-platform** (works on both NixOS and macOS):
```nix
let module = { ... }; in
{
  flake.nixosModules.foo = module;
  flake.darwinModules.foo = module;
}
```
Examples: `git`, `zsh`, `ssh`, `nvim`, `cli`, `programming`, `opencode`, `theming`, `sops`.

**NixOS-only** (needs Linux-specific things like systemd, nvidia, hyprland):
```nix
{ flake.nixosModules.foo = { ... }; }
```
**macOS-only** (needs darwin-specific things like yabai, skhd):
```nix
{ flake.darwinModules.foo = { ... }; }
```

### Custom Options
| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `my.user.name` | str | `"felipe"` | User account name used throughout configs |
| `my.colors` | attrsOf str | (from stylix) | Semantic color palette: background, surface, primary, secondary, accent, error, warning, etc. |
| `my.rgb.enable` | bool | false | OpenRGB lighting synced to theme |
| `my.rgb.color` | hex str | — | RGB color (e.g., `config.my.colors.secondary`) |
| `my.k3s.tlsSans` | listOf str | — | Extra TLS SANs for k3s API |
| `myConfig.restic` | submodule | — | Restic backup config (paths, prune opts, timer) |

### Profiles
- `base` — core, theming, zsh, git, ssh, nvim, cli, btop, yazi
- `desktop` — audio, network, hyprland, noctalia, firefox, dolphin, alacritty, kdeconnect, bitwarden

## Hosts

### zaros (NixOS, x86_64-linux)
Hyprland + Noctalia shell desktop. Imports: identity, base, desktop, sops, restic, nvidia, gaming, rgb, microbot, programming, rustdesk, opencode, ollama, office, virtualization, flatpak, webos-dev-manager, openssh, tailscale, docker, k8s.

### saradomin (NixOS, x86_64-linux)
Headless home server with k3s. Disk partitioned via disko. Imports: disko, identity, base, sops, openssh, k3s, tailscale.

### macbook (nix-darwin, aarch64-darwin)
Dev laptop with yabai + skhd + sketchybar. Imports: identity, theming, core, yabai, skhd, borders, sketchybar, zsh, git, sops, ssh, nvim, cli, btop, alacritty, firefox, programming, opencode, k8s.

## Home-Manager
All user config goes through `home-manager.users.${user}` where `user = config.my.user.name`. Global settings: `useGlobalPkgs=true`, `useUserPackages=true`, backup extension `"bak"`.

## Theming
Stylix with catppuccin-mocha base16 scheme. Wallpaper set to `assets/wallpapers/catppuccin-mocha.png`. Uses `config.my.colors` for semantic color access in all modules. Firefox themed via pywalfox.

## Secrets
SOPS with single age key. Encrypted file: `secrets/secrets.yaml`. Edit with `make secrets` or `sops secrets/secrets.yaml`. Age key location per host: `/var/lib/sops-age/keys.txt`.

## Deployment
```sh
make switch HOST=zaros       # build + apply
make build HOST=saradomin    # build only (check)
make fmt                     # format all tracked .nix files
make secrets                 # edit secrets

# macOS
darwin-rebuild switch --flake .#macbook

# saradomin-vm variant also available
nixos-rebuild switch --flake .#saradomin-vm
```
