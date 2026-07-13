{ self, ... }:
{
  flake.nixosModules.saradomin =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        self.nixosModules.saradominDisk
        self.nixosModules.saradominHardware
        self.nixosModules.identity
        self.nixosModules.base
        self.nixosModules.sops
        self.nixosModules.openssh
        self.nixosModules.k3s
        self.nixosModules.tailscale
      ];

      networking.hostName = "saradomin";

      home-manager.users.${user} = {
        imports = [ self.homeModules.linux-base ];
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
      system.stateVersion = "25.11";

      security.pki.certificateFiles = [
        ../../../certs/saradomin-internal-ca.crt
      ];

      users.users.${user}.openssh.authorizedKeys.keyFiles = [
        ../../../keys/zaros.pub
        ../../../keys/bitbaut.pub
      ];
    };
}
