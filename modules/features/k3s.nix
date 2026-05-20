{
  flake.nixosModules.k3s = {
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        "--disable=traefik"
      ];
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
}
