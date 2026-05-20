{ self, ... }:
{
  flake.darwinModules.macbook = {
    imports = [
      self.darwinModules.identity
      self.darwinModules.theming
      self.darwinModules.core
      self.darwinModules.yabai
      self.darwinModules.skhd
      self.darwinModules.borders
      self.darwinModules.sketchybar
      self.darwinModules.zsh
      self.darwinModules.git
      self.darwinModules.sops
      self.darwinModules.ssh
      self.darwinModules.nvim
      self.darwinModules.cli
      self.darwinModules.btop
      self.darwinModules.alacritty
      self.darwinModules.firefox
      self.darwinModules.programming
      self.darwinModules.opencode
      self.darwinModules.k8s
    ];

    networking.hostName = "macbook";
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 4;

    my.user.name = "felipeautentique";
  };
}
