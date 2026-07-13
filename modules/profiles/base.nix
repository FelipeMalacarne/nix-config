{ self, ... }:
{
  flake.nixosModules.base = {
    imports = [
      self.nixosModules.core
      self.nixosModules.theming
      self.nixosModules.zsh
      self.nixosModules.ssh
    ];
  };

  flake.homeModules.base = {
    imports = with self.homeModules; [
      zsh
      git
      ssh
      neovim
      cli
      btop
    ];
  };

  flake.homeModules.linux-base = {
    imports = with self.homeModules; [
      base
      yazi
    ];
  };
}
