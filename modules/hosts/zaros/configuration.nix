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
        identity
        base
        desktop
        zarosDesktopPolicy
        sops
        restic
        sunshine
        nvidia
        gaming
        rgb
        programming
        ollama
        virtualization
        flatpak
        openssh
        tailscale
        docker
        k8s
      ];

      home-manager.users.${user}.imports = with self.homeModules; [
        linux-base
        desktop
        gaming
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

      myConfig.restic = {
        enable = true;
        paths = [
          "/home/${user}/Documents"
          "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
          "/home/${user}/.runelite/screenshots"

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
