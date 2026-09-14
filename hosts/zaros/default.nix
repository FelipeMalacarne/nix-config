{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  user = config.my.user.name;
in
{
  imports = [
    ./hardware.nix
    self.modules.nixos.base
    self.modules.nixos.desktop
    ./desktop.nix
    self.modules.nixos.sops
    self.modules.nixos.development
  ];

  home-manager.users.${user}.imports = with self.modules.homeManager; [
    linux-base
    desktop
    ankama-launcher
    scape2011
    development
    microbot
    office
    webos-dev-manager
    torrent
  ];

  environment.systemPackages = [
    pkgs.google-chrome
  ];
  programs.chromium.enable = true;

  networking.hostName = "zaros";

  console = {
    font = "ter-v24b";
    packages = [ pkgs.terminus_font ];
  };

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
  my.hermes-agent.enable = true;
  my.hermes-agent.web = {
    enable = true;
    publicUrl = "https://zaros.osiris-fish.ts.net";
    restartTriggers = [ ../../secrets/hermes-web.yaml ];
    environmentFile = lib.mkIf (
      config.my.hermes-agent.enable && config.my.hermes-agent.web.enable
    ) config.sops.secrets.hermes-web.path;
  };
  sops.secrets.hermes-web =
    lib.mkIf (config.my.hermes-agent.enable && config.my.hermes-agent.web.enable)
      {
        sopsFile = ../../secrets/hermes-web.yaml;
        key = "environment";
        owner = user;
        mode = "0400";
      };
  system.stateVersion = "24.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
    ../../keys/bitbaut.pub
  ];
}
