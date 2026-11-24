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

  # Work stays on skhd's alt+shift+b default profile.
  services.skhd.skhdConfig = ''
    alt + shift - p : open -na Firefox --env MOZ_DISABLE_SAFE_MODE_KEY=1 --args -P personal
  '';

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
      # The existing default profile holds work accounts.
      my.firefox = {
        defaultProfileLabel = "work";
        extraProfiles = [ "personal" ];
      };

      home.activation.installZarosAuthorizedKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 700 -d "$HOME/.ssh"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 ${../../keys/zaros.pub} "$HOME/.ssh/authorized_keys"
      '';
    };
}
