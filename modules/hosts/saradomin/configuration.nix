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
      ];

      networking.hostName = "saradomin";
      system.stateVersion = "24.11";

      security.pki.certificateFiles = [
        ../../../certs/saradomin-internal-ca.crt
      ];

      users.users.${user}.openssh.authorizedKeys.keyFiles = [
        ../../../keys/zaros.pub
        ../../../keys/bitbaut.pub
      ];
    };
}
