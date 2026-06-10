let
  baseModule =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.home-manager.users.${user}.home.homeDirectory;
    in
    {
      sops.secrets."zaros-private-key" = {
        owner = user;
        path = "${homeDirectory}/.ssh/zaros";
        mode = "0600";
      };

      sops.secrets."zamorak-private-key" = {
        owner = user;
        path = "${homeDirectory}/.ssh/zamorak";
        mode = "0600";
      };

      sops.secrets."saradomin-private-key" = {
        owner = user;
        path = "${homeDirectory}/.ssh/saradomin";
        mode = "0600";
      };

      home-manager.users.${user}.programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "github.com" = {
            hostname = "ssh.github.com";
            port = 443;
            user = "git";
            identityFile = "~/.ssh/zaros";
            extraOptions.IdentitiesOnly = "yes";
          };

          "zamorak" = {
            hostname = "137.131.204.251";
            port = 22;
            user = "ubuntu";
            identityFile = "~/.ssh/zamorak";
          };

          "saradomin" = {
            user = "felipe";
            identityFile = "~/.ssh/zaros";
            extraOptions.IdentitiesOnly = "yes";
          };

          "macbook" = {
            user = "felipeautentique";
            identityFile = "~/.ssh/zaros";
            extraOptions.IdentitiesOnly = "yes";
          };

          "zaros" = {
            user = "felipe";
            identityFile = "~/.ssh/zaros";
            extraOptions.IdentitiesOnly = "yes";
          };
        };
      };
    };

  nixosModule =
    {
      config,
      ...
    }:
    let
      user = config.my.user.name;
    in
    {
      imports = [ baseModule ];

      systemd.tmpfiles.rules = [
        "d ${config.users.users.${user}.home}/.ssh 0700 ${user} users -"
      ];
    };
in
{
  flake.nixosModules.ssh = nixosModule;
  flake.darwinModules.ssh = baseModule;
}
