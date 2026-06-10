{ self, ... }:
{
  flake.darwinModules.macbook =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
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

      services.openssh.enable = true;

      my.user.name = "felipeautentique";

      home-manager.users.${user} =
        { lib, ... }:
        {
          home.activation.installZarosAuthorizedKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 700 -d "$HOME/.ssh"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${../../../keys/zaros.pub} "$HOME/.ssh/authorized_keys"
          '';
        };
    };
}
