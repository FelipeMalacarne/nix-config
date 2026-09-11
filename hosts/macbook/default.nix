{
  config,
  pkgs,
  self,
  ...
}:
let
  user = config.my.user.name;
in
{
  imports = [
    self.modules.darwin.base
    self.modules.darwin.yabai
    self.modules.darwin.skhd
    self.modules.darwin.borders
    self.modules.darwin.sketchybar
    self.modules.darwin.sops
    self.modules.darwin.development
    self.modules.darwin.firefox
    # self.modules.darwin.openclaw
  ];

  networking.hostName = "macbook";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 4;

  services.openssh.enable = true;

  my.user.name = "felipeautentique";

  home-manager.users.${user} =
    { lib, ... }:
    {
      imports = with self.modules.homeManager; [
        base
        ghostty
        firefox
        development
        sketchybar
      ];

      home.activation.installZarosAuthorizedKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 700 -d "$HOME/.ssh"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${../../keys/zaros.pub} "$HOME/.ssh/authorized_keys"
      '';
    };
}
