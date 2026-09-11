{ self, ... }:
{
  flake.nixosModules.zaros =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = with self.nixosModules; [
        zarosHardware
        base
        desktop
        zarosDesktopPolicy
        sops
        programming
        k8s
      ];

      home-manager.users.${user}.imports = with self.homeModules; [
        linux-base
        desktop
        ankama-launcher
        scape2011
        programming
        opencode
        microbot
        office
        webos-dev-manager
        k8s
        torrent
      ];

      environment.systemPackages = [
        pkgs.google-chrome
      ];
      programs.chromium.enable = true;

      networking.hostName = "zaros";

      systemd.services.enable-wol = {
        description = "Enable Wake-on-LAN on enp12s0";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-pre.target" ];
        before = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp12s0 wol g";
          RemainAfterExit = "yes";
        };
      };

      my.rgb = {
        enable = true;
        color = config.my.colors.secondary;
      };

      my.restic = {
        enable = true;
        paths = [
          "/home/${user}/Documents"
          "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
          "/home/${user}/.runelite/screenshots"

        ];
      };
      my.docker.enable = true;
      my.virtualization.enable = true;
      my.ollama.enable = true;
      my.sunshine.enable = true;
      my.flatpak.enable = true;
      my.openssh.enable = true;
      my.tailscale.enable = true;
      my.nvidia.enable = true;
      my.gaming.enable = true;
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
