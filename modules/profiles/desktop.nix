{ self, ... }:
{
  flake.nixosModules.desktop = {
    imports = [
      self.nixosModules.audio
      self.nixosModules.network
      self.nixosModules.sddm
      self.nixosModules.i3
      self.nixosModules.hyprland
      self.nixosModules.noctalia
      self.nixosModules.firefox
      self.nixosModules.dolphin
      self.nixosModules.kdeconnect
    ];
  };

  flake.homeModules.desktop = {
    imports = with self.homeModules; [
      i3
      hyprland
      noctalia
      firefox
      dolphin
      alacritty
      kdeconnect
      bitwarden
    ];
  };
}
