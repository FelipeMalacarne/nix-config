let
  homeModule =
    { config, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = config.my.infrastructure.ssh.hosts;
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

  darwinModule =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
    in
    {
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
  flake.modules.nixos.ssh = nixosModule;
  flake.modules.darwin.ssh = darwinModule;
  flake.modules.homeManager.ssh = homeModule;
}
