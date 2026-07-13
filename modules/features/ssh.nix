let
  homeModule = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          HostName = "ssh.github.com";
          Port = 443;
          User = "git";
          IdentityFile = "~/.ssh/zaros";
          IdentitiesOnly = "yes";
        };

        "zamorak" = {
          Hostname = "137.131.204.251";
          Port = 22;
          User = "ubuntu";
          IdentityFile = "~/.ssh/zamorak";
        };

        "saradomin" = {
          User = "felipe";
          IdentityFile = "~/.ssh/zaros";
          IdentitiesOnly = "yes";
        };

        "macbook" = {
          User = "felipeautentique";
          IdentityFile = "~/.ssh/zaros";
          IdentitiesOnly = "yes";
        };

        "zaros" = {
          User = "felipe";
          IdentityFile = "~/.ssh/zaros";
          IdentitiesOnly = "yes";
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
      homeDirectory = config.users.users.${user}.home;
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

      systemd.tmpfiles.rules = [
        "d ${homeDirectory}/.ssh 0700 ${user} users -"
      ];
    };

  darwinModule =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
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
    };
in
{
  flake.nixosModules.ssh = nixosModule;
  flake.darwinModules.ssh = darwinModule;
  flake.homeModules.ssh = homeModule;
}
