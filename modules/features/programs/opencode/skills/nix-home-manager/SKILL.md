---
name: nix-home-manager
description: Use when editing NixOS, Home Manager, nix-darwin, flakes, Nix modules, or this nix-config repository.
---

# Nix Home Manager

Use native module options before writing raw config files. Verify option shapes from module source, generated options, or documented schema when unsure.

For this nix-config repo:

- Preserve the cross-platform module registration pattern.
- Route user config through `home-manager.users.<user>`.
- Register supported aspects under `flake.modules.nixos`, `flake.modules.darwin`, and/or `flake.modules.homeManager`; hosts consume `self.modules` and explicitly select optional features.
- Follow host -> profile -> feature -> upstream dependencies. Do not add redundant feature enable selectors or implicitly activate optional integrations in base.
- Format touched Nix files before completion.
- Do not run Nix eval or build commands when the user has asked to avoid them.
