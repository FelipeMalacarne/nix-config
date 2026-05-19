{ self, ... }:
{
  flake.nixosModules.desktop = {
    imports = [
      self.nixosModules.audio
      self.nixosModules.network
      self.nixosModules.hyprland
      self.nixosModules.noctalia
      self.nixosModules.firefox
      self.nixosModules.dolphin
      self.nixosModules.alacritty
      self.nixosModules.kdeconnect
      self.nixosModules.bitwarden
    ];
  };
}
