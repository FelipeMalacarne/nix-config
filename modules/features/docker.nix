{
  flake.nixosModules.docker =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      options.my.docker.enable = lib.mkEnableOption "Docker";

      config = lib.mkIf config.my.docker.enable {
        boot.binfmt = {
          emulatedSystems = [ "aarch64-linux" ];
          preferStaticEmulators = true;
        };
        virtualisation.docker.enable = true;
        users.users.${user}.extraGroups = [ "docker" ];
      };
    };
}
