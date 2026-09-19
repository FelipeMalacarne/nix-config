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
  imports = [
    ./disk.nix
    ./hardware.nix
    self.modules.nixos.server
  ];

  networking.hostName = "saradomin";

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
  my.adguard-home = {
    enable = true;
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
  my.openssh.enable = true;
  my.tailscale.enable = true;
  my.k3s.enable = true;
  system.stateVersion = "25.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
    ../../keys/bitbaut.pub
  ];
}
