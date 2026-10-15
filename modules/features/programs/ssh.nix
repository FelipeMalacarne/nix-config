{ config, ... }:
let
  registry = config.flake.modules;
  platformModule = { config, ... }: {
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.ssh ];
  };

  homeModule =
    { config, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = config.my.infrastructure.ssh.hosts;
      };
    };

  nixosCredentials =
    {
      config,
      ...
    }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
    in
    {
      imports = [
        registry.nixos.ssh
        registry.nixos.sops
      ];

      home-manager.users.${user}.imports = [ registry.homeManager.sops ];

      sops.secrets = builtins.listToAttrs (
        map (name: {
          name = "${name}-private-key";
          value = {
            owner = user;
            path = "${homeDirectory}/.ssh/${name}";
            mode = "0600";
          };
        }) config.my.infrastructure.ssh.privateKeys
      );

      systemd.tmpfiles.rules = [
        "d ${homeDirectory}/.ssh 0700 ${user} users -"
      ];
    };

  darwinCredentials =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
    in
    {
      imports = [
        registry.darwin.ssh
        registry.darwin.sops
      ];

      home-manager.users.${user}.imports = [ registry.homeManager.sops ];

      sops.secrets = builtins.listToAttrs (
        map (name: {
          name = "${name}-private-key";
          value = {
            owner = user;
            path = "${homeDirectory}/.ssh/${name}";
            mode = "0600";
          };
        }) config.my.infrastructure.ssh.privateKeys
      );
    };
in
{
  flake.modules.nixos.ssh = platformModule;
  flake.modules.darwin.ssh = platformModule;
  flake.modules.homeManager.ssh = homeModule;

  flake.modules.nixos.ssh-credentials = nixosCredentials;
  flake.modules.darwin.ssh-credentials = darwinCredentials;
}
