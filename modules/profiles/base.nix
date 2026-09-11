{ self, ... }:
{
  flake.nixosModules.base = {
    imports = [
      self.nixosModules.identity
      self.nixosModules.core
      self.nixosModules.theming
      self.nixosModules.zsh
      self.nixosModules.ssh
      self.nixosModules.optional-features
    ];
  };

  flake.darwinModules.base = {
    imports = [
      self.darwinModules.identity
      self.darwinModules.core
      self.darwinModules.theming
      self.darwinModules.zsh
      self.darwinModules.ssh
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
