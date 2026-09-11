{
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    {
      options.my.tailscale.enable = lib.mkEnableOption "Tailscale";
      config = lib.mkIf config.my.tailscale.enable {
        services.tailscale.enable = true;

        networking.firewall = {
          trustedInterfaces = [ "tailscale0" ];
          allowedUDPPorts = [ 41641 ];
        };
      };
    };
}
