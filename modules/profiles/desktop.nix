{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.desktop = {
    imports = [
      registry.nixos.audio
      registry.nixos.network
      registry.nixos.i3
      registry.nixos.hyprland
      registry.nixos.umbriel
      registry.nixos.noctalia
      registry.nixos.firefox
      registry.nixos.dolphin
      registry.nixos.kdeconnect
      registry.nixos.desktop-foundation
    ];
  };

  flake.modules.homeManager.desktop = {
    imports = with registry.homeManager; [
      desktop-foundation
      i3
      hyprland
      umbriel
      noctalia
      caelestia
      firefox
      dolphin
      ghostty
      kdeconnect
      bitwarden
    ];
  };
}
