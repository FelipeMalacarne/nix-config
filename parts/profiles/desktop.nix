{
  flake.nixosModules.desktop = {
    imports = [
      ../../modules/features/audio.nix
      ../../modules/features/network.nix
      ../../modules/features/hyprland
      ../../modules/features/noctalia.nix
      ../../modules/features/firefox.nix
      ../../modules/features/dolphin.nix
      ../../modules/features/alacritty.nix
      ../../modules/features/kdeconnect.nix
      ../../modules/features/bitwarden.nix
    ];
  };
}
