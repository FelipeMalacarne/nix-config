{ config, lib, ... }:
let
  registry = config.flake.modules;
  platformModule = {
    home-manager.sharedModules = [ registry.homeManager.ssh ];
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

  credentialsModule =
    platform:
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
    in
    {
      imports = [
        registry.${platform}.ssh
        registry.${platform}.sops
      ];

      home-manager.sharedModules = [ registry.homeManager.sops ];

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
    }
    // lib.optionalAttrs (platform == "nixos") {
      systemd.tmpfiles.rules = [
        "d ${homeDirectory}/.ssh 0700 ${user} users -"
      ];
    };
in
{
  flake.modules.nixos.ssh = platformModule;
  flake.modules.darwin.ssh = platformModule;
  flake.modules.homeManager.ssh = homeModule;

  flake.modules.nixos.ssh-credentials = credentialsModule "nixos";
  flake.modules.darwin.ssh-credentials = credentialsModule "darwin";
}
