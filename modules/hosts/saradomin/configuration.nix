{ inputs, self, ... }:
{
  flake.nixosModules.saradomin = { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        self.nixosModules.saradominHardware
        self.nixosModules.identity
        self.nixosModules.base
        self.nixosModules.sops
        self.nixosModules.openssh
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
      ];

      networking.hostName = "saradomin";
      myConfig.colorScheme = "catppuccin-mocha";
      system.stateVersion = "24.11";

      security.pki.certificateFiles = [
        ../../../certs/saradomin-internal-ca.crt
      ];

      users.users.${user}.openssh.authorizedKeys.keyFiles = [
        ../../../keys/zaros.pub
      ];
    };
}
