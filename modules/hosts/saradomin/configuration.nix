{ self, ... }:
{
  flake.nixosModules.saradomin =
    { config, ... }:
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
