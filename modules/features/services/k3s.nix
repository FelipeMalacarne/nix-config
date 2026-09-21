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
      options.my.k3s.enable = lib.mkEnableOption "k3s";

      config = lib.mkIf config.my.k3s.enable {
        services.k3s = {
          enable = true;
          role = "server";
          extraFlags = toString ([ "--disable=traefik" ] ++ map (san: "--tls-san=${san}") cfg.tlsSans);
        };

        # Media containers use PUID/PGID 1001 and need to create library and
        # download entries in these hostPath directories.
        systemd.tmpfiles.rules = [
          "d /data/media/movies          0775 1001 1001 -"
          "d /data/media/tv              0775 1001 1001 -"
          "d /data/media/music           0775 1001 1001 -"
          "d /data/media/books           0775 1001 1001 -"
          "d /data/downloads             0775 1001 1001 -"
          "d /data/downloads/complete    0775 1001 1001 -"
          "d /data/downloads/incomplete  0775 1001 1001 -"
        ];

        # open k3s api port within tailscale interface only
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 6443 ];
      };
    };
}
