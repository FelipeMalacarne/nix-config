{ self, ... }:
{
  flake.nixosModules.zaros =
    { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = with self.nixosModules; [
        zarosHardware
        identity
        base
        desktop
        sops
        restic
        nvidia
        gaming
        rgb
        microbot
        programming
        opencode
        ollama
        office
        virtualization
        flatpak
        openssh
        tailscale
        docker
        k8s
      ];

      networking.hostName = "zaros";

      my.rgb = {
        enable = true;
        color = config.my.colors.secondary;
      };

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
