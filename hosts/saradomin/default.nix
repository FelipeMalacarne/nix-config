{
  config,
  pkgs,
  self,
  ...
}:
let
  user = config.my.user.name;
  inherit (config.my.infrastructure.machines) saradomin zaros;
in
{
  imports = with self.modules.nixos; [
    ./disk.nix
    ./hardware.nix
    server
    ssh-credentials
    internal-ca
    adguard-home
    k3s
    openssh
    tailscale
    ai-memory-server
    ai-memory-backup
  ];

  networking.hostName = "saradomin";

  my.ai.memory.server.hostName = saradomin.tailnetName;
  services.ai-memory.enableWeb = true;

  home-manager.users.${user} = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "wake-zaros";
        text = ''
          wakeonlan ${zaros.macAddress}
        '';
      })
    ];
  };

  my.k3s.tlsSans = [
    saradomin.tailnetAddress
    "saradomin"
    "saradomin.tail34cc60.ts.net"
  ];

  # Media containers use PUID/PGID 1001 and need to create library and
  # download entries in these hostPath directories. Keep the `e` rules
  # alongside `d`: `d` covers a fresh host, while `e` repairs ownership
  # and mode on directories that already existed before this config.
  systemd.tmpfiles.rules =
    let
      mediaPaths = [
        "/data"
        "/data/media"
        "/data/media/movies"
        "/data/media/tv"
        "/data/media/music"
        "/data/media/books"
        "/data/downloads"
        "/data/downloads/complete"
        "/data/downloads/incomplete"
      ];
    in
    map (path: "d ${path} 0775 1001 1001 -") mediaPaths
    ++ map (path: "e ${path} 0775 1001 1001 -") mediaPaths;

  my.adguard-home = {
    listenAddresses = [
      saradomin.lanAddress
      saradomin.tailnetAddress
    ];
    webAddress = saradomin.lanAddress;
    webProxyCidrs = [ "10.42.0.0/16" ];
    lanCidrs = [ "10.10.0.0/22" ];
    zones = [
      "saradomin.ftm.dev.br"
      "saradomin"
    ];
    views = [
      {
        clientCidr = "10.10.0.0/22";
        answer = saradomin.lanAddress;
      }
      {
        clientCidr = "100.64.0.0/10";
        answer = "100.95.138.31";
      }
    ];
  };
  system.stateVersion = "25.11";
}
