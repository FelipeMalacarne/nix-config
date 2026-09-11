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
