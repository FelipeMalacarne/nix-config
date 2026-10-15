{
  flake.modules.nixos.k3s =
    { config, lib, ... }:
    let
      cfg = config.my.k3s;
    in
    {
      options.my.k3s.tlsSans = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional TLS SANs to include in the k3s API server certificate.";
      };

      config = {
        services.k3s = {
          enable = true;
          role = "server";
          extraFlags = toString ([ "--disable=traefik" ] ++ map (san: "--tls-san=${san}") cfg.tlsSans);
        };

        # open k3s api port within tailscale interface only
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 6443 ];
      };
    };
}
