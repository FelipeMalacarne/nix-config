# nix-config

Felipe's NixOS/nix-darwin system configuration.

## Hosts

| Host | OS | Role |
|------|----|------|
| `macbook` | nix-darwin (aarch64) | MacBook — dev workstation |
| `zaros` | NixOS (x86_64) | Desktop — gaming + dev |
| `saradomin` | NixOS (x86_64) | Home server |

## Structure

```
hosts/          per-host entry points + hardware config
modules/
  presets/      bundles of features
    base.nix      core, shell, git, ssh, nvim, cli, fonts
    desktop.nix   audio, hyprland, browser, bitwarden, dolphin
  features/     individual opt-in modules
keys/           SSH public keys
certs/          internal CA certificates
secrets/        sops-encrypted secrets (secrets.yaml)
```

## Setup

### 1. Age key (required for secrets)

Place your age private key on each host:

```bash
sudo mkdir -p /var/lib/sops-age
echo "AGE-SECRET-KEY-..." | sudo tee /var/lib/sops-age/keys.txt
sudo chmod 600 /var/lib/sops-age/keys.txt
```

The public key must match the one in `.sops.yaml`.

### 2. Deploy

**NixOS:**
```bash
nixos-rebuild switch --flake .#zaros
nixos-rebuild switch --flake .#saradomin
```

**macOS:**
```bash
darwin-rebuild switch --flake .#macbook
```

## Secrets

Secrets live in `secrets/secrets.yaml`, encrypted with sops + age.

```bash
# edit secrets
sops secrets/secrets.yaml

# add a new secret to nix
sops.secrets."my-secret" = {};
# available at: config.sops.secrets."my-secret".path
```
