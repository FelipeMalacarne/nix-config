{ inputs, self, ... }:
{
  flake.nixosModules.zaros = { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        self.nixosModules.zarosHardware
        self.nixosModules.identity
        self.nixosModules.base
        self.nixosModules.desktop
        self.nixosModules.sops
        self.nixosModules.restic
        self.nixosModules.nvidia
        self.nixosModules.gaming
        self.nixosModules.microbot
        self.nixosModules.programming
        self.nixosModules.opencode
        self.nixosModules.ollama
        self.nixosModules.office
        self.nixosModules.virtualization
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.flatpak
        self.nixosModules.openssh
        self.nixosModules.tailscale
        self.nixosModules.docker
      ];

      networking.hostName = "zaros";

      myConfig.colorScheme = "catppuccin-mocha";
      myConfig.restic = {
        enable = true;
        paths = [
          "/home/${user}/Documents"
          "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
        ];
      };
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
