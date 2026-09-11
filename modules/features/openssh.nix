{
  flake.nixosModules.openssh =
    { config, lib, ... }:
    {
      options.my.openssh.enable = lib.mkEnableOption "OpenSSH";
      config = lib.mkIf config.my.openssh.enable {
        services.openssh = {
          enable = true;
          openFirewall = true;
          settings.PermitRootLogin = "no";
        };
      };
    };
}
