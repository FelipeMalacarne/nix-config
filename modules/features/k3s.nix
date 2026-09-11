{
  flake.nixosModules.k3s =
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
      options.my.k3s.enable = lib.mkEnableOption "k3s";

      config = lib.mkIf config.my.k3s.enable {
        services.k3s = {
          enable = true;
          role = "server";
          extraFlags = toString ([ "--disable=traefik" ] ++ map (san: "--tls-san=${san}") cfg.tlsSans);
        };

        # host paths that k3s pods mount via hostPath / local-path PVCs
        systemd.tmpfiles.rules = [
          "d /data/media/movies  0755 root root -"
          "d /data/media/tv      0755 root root -"
          "d /data/media/music   0755 root root -"
          "d /data/media/books   0755 root root -"
          "d /data/downloads     0755 root root -"
        ];

        # open k3s api port within tailscale interface only
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 6443 ];
      };
    };
}
