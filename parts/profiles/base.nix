{ self, ... }:
{
  flake.nixosModules.base = {
    imports = [
      self.nixosModules.core
      self.nixosModules.theming
      self.nixosModules.zsh
      self.nixosModules.git
      self.nixosModules.ssh
      self.nixosModules.nvim
      self.nixosModules.cli
      self.nixosModules.btop
      self.nixosModules.yazi
      self.nixosModules.fonts
    ];
  };
}
