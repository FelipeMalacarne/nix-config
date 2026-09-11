{ self, ... }:
{
  flake.darwinModules.macbook =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        self.darwinModules.base
        self.darwinModules.yabai
        self.darwinModules.skhd
        self.darwinModules.borders
        self.darwinModules.sketchybar
        self.darwinModules.sops
        self.darwinModules.programming
        self.darwinModules.k8s
        self.darwinModules.firefox
        # self.darwinModules.openclaw
      ];

      networking.hostName = "macbook";
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.stateVersion = 4;

      services.openssh.enable = true;

      my.user.name = "felipeautentique";

      home-manager.users.${user} =
        { lib, ... }:
        {
          imports = with self.homeModules; [
            base
            ghostty
            firefox
            programming
            opencode
            k8s
            sketchybar
          ];

          home.activation.installZarosAuthorizedKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 700 -d "$HOME/.ssh"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${../../../keys/zaros.pub} "$HOME/.ssh/authorized_keys"
          '';
        };
    };
}
