{
  config,
  pkgs,
  self,
  ...
}:
let
  user = config.my.user.name;
in
{
  imports = with self.modules.nixos; [
    ./disk.nix
    ./hardware.nix
    server
    ssh-credentials
    adguard-home
    k3s
    openssh
    tailscale
    ai-memory-server
    ai-memory-backup
  ];

  networking.hostName = "saradomin";

  my.ai.memory.server.hostName = "saradomin.osiris-fish.ts.net";
  services.ai-memory.enableWeb = true;

  home-manager.users.${user} = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "wake-zaros";
        text = ''
          wakeonlan 04:7c:16:db:d9:e1
        '';
      })
    ];
  };

  my.k3s.tlsSans = [
    "100.106.58.87"
    "saradomin"
    "saradomin.tail34cc60.ts.net"
  ];

  # Media containers use PUID/PGID 1001 and need to create library and
  # download entries in these hostPath directories. Keep the `e` rules
  # alongside `d`: `d` covers a fresh host, while `e` repairs ownership
  # and mode on directories that already existed before this config.
  systemd.tmpfiles.rules = [
    "d /data 0775 1001 1001 -"
    "d /data/media 0775 1001 1001 -"
    "d /data/media/movies 0775 1001 1001 -"
    "d /data/media/tv 0775 1001 1001 -"
    "d /data/media/music 0775 1001 1001 -"
    "d /data/media/books 0775 1001 1001 -"
    "d /data/downloads 0775 1001 1001 -"
    "d /data/downloads/complete 0775 1001 1001 -"
    "d /data/downloads/incomplete 0775 1001 1001 -"
    "e /data 0775 1001 1001 -"
    "e /data/media 0775 1001 1001 -"
    "e /data/media/movies 0775 1001 1001 -"
    "e /data/media/tv 0775 1001 1001 -"
    "e /data/media/music 0775 1001 1001 -"
    "e /data/media/books 0775 1001 1001 -"
    "e /data/downloads 0775 1001 1001 -"
    "e /data/downloads/complete 0775 1001 1001 -"
    "e /data/downloads/incomplete 0775 1001 1001 -"
  ];

  my.adguard-home = {
    listenAddresses = [
      "10.10.0.10"
      "100.106.58.87"
    ];
    webAddress = "10.10.0.10";
    webProxyCidrs = [ "10.42.0.0/16" ];
    lanCidrs = [ "10.10.0.0/22" ];
    zones = [
      "saradomin.ftm.dev.br"
      "saradomin"
    ];
    views = [
      {
        clientCidr = "10.10.0.0/22";
        answer = "10.10.0.10";
      }
      {
        clientCidr = "100.64.0.0/10";
        answer = "100.95.138.31";
      }
    ];
  };
  system.stateVersion = "25.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
    ../../keys/bitbaut.pub
  ];
}
