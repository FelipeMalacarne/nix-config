{
  config,
  pkgs,
  ...
}:
let
  user = config.my.user.name;
in
{
  networking.hostName = "macbook";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 4;

  services.openssh.enable = true;

  my = {
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
      my.infrastructure.ssh.hosts = config.my.infrastructure.ssh.hosts;

      home.activation.installZarosAuthorizedKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 700 -d "$HOME/.ssh"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${../../keys/zaros.pub} "$HOME/.ssh/authorized_keys"
      '';
    };
}
