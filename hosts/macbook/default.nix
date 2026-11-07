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
    self.modules.darwin.mac-app-util
    self.modules.darwin.yabai
    self.modules.darwin.skhd
    self.modules.darwin.borders
    self.modules.darwin.sketchybar
    self.modules.darwin.ssh-credentials
    self.modules.darwin.development
    self.modules.darwin.programming-credentials
    self.modules.darwin.k8s-credentials
    self.modules.darwin.ai
    self.modules.darwin.claude-gateway
    self.modules.darwin.firefox
  ];

  networking.hostName = "macbook";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 4;

  services.openssh.enable = true;

  my = {
    ai.memory.client.serverUrl = "https://saradomin.osiris-fish.ts.net:8443";
    user.name = "felipeautentique";

    infrastructure.ssh.hosts = {
      "github.com".IdentityFile = "~/.ssh/bitbaut";

      "github-zaros" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        IdentityFile = "~/.ssh/zaros";
        IdentitiesOnly = "yes";
      };
    };
  };

  home-manager.users.${user} =
    { lib, ... }:
    {
      imports = with self.modules.homeManager; [
        ghostty
        firefox
        sketchybar
      ];

      my.infrastructure.ssh.hosts = config.my.infrastructure.ssh.hosts;

      home.activation.installZarosAuthorizedKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 700 -d "$HOME/.ssh"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${../../keys/zaros.pub} "$HOME/.ssh/authorized_keys"
      '';
    };
}
