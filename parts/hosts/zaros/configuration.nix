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
        ../../../modules/features/sops.nix
        ../../../modules/features/restic.nix
        ../../../modules/features/nvidia.nix
        ../../../modules/features/gaming.nix
        ../../../modules/features/microbot.nix
        ../../../modules/features/programming.nix
        ../../../modules/features/opencode.nix
        ../../../modules/features/ollama.nix
        ../../../modules/features/office.nix
        ../../../modules/features/virtualization.nix
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs; };
          nixpkgs.overlays = [ inputs.nur.overlays.default ];
        }
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
