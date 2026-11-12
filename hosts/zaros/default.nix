{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  user = config.my.user.name;
  inherit (config.my.infrastructure) machines;
in
{
  imports = with self.modules.nixos; [
    ./hardware.nix
    base
    desktop
    noctalia-greeter
    ./desktop.nix
    ssh-credentials
    development
    programming-credentials
    k8s-credentials
    ai
    claude-remote-control
    docker
    flatpak
    gaming
    recording
    hermes-agent
    nvidia
    ollama
    internal-ca
    openssh
    restic
    rgb
    tailscale
    virtualization
    wol
  ];

  home-manager.users.${user} = {
    imports = with self.modules.homeManager; [
      # ankama-launcher
      artcraft
      scape2011
      microbot
      chronicle
      office
      orca
      webapps
      webos-dev-manager
      torrent
      signal
    ];

    my.infrastructure.ssh.hosts.saradomin.HostName = machines.saradomin.lanAddress;

    programs.artcraft = {
      apps.filmcraft.enable = true;
      mcp.enable = true;
    };
  };

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  networking.hostName = "zaros";

  console = {
    font = "ter-v24b";
    packages = [ pkgs.terminus_font ];
  };

  my = {
    wol.interface = "enp12s0";
    rgb.color = config.my.colors.secondary;
    restic = {
      paths = [
        "/home/${user}/Documents"
        "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
        "/home/${user}/.runelite/screenshots"

      ];
    };
    ai = {
      memory.client.serverUrl = "https://${machines.saradomin.tailnetName}:8443";
      hermes.web = {
        enable = true;
        publicUrl = "https://${machines.zaros.tailnetName}";
        restartTriggers = [ ../../secrets/hermes-web.yaml ];
        environmentFile = lib.mkIf config.my.ai.hermes.web.enable config.sops.secrets.hermes-web.path;
      };
    };
  };

  sops.secrets.hermes-web = lib.mkIf config.my.ai.hermes.web.enable {
    sopsFile = ../../secrets/hermes-web.yaml;
    key = "environment";
    owner = user;
    mode = "0400";
  };
  system.stateVersion = "24.11";
}
