{
  flake.nixosModules.docker =
    { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      boot.binfmt = {
        emulatedSystems = [ "aarch64-linux" ];
        preferStaticEmulators = true;
      };
      virtualisation.docker.enable = true;
      users.users.${user}.extraGroups = [ "docker" ];
    };
}
