{
  flake.nixosModules.docker = { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      virtualisation.docker.enable = true;
      users.users.${user}.extraGroups = [ "docker" ];
    };
}
