---
name: nix-home-manager
description: Use when editing NixOS, Home Manager, nix-darwin, flakes, or .nix module files.
---

# Nix Home Manager

Use native module options before writing raw config files. Verify option shapes from the module source or generated options when unsure.

For this nix-config repo, preserve the cross-platform module registration pattern and route user config through `home-manager.users.<user>`.

Before claiming success, run formatting and a Nix evaluation or build check for the touched host.
