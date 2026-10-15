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
    docker
    artcraft
    flatpak
    gaming
    recording
    hermes-agent
    nvidia
    ollama
    openssh
    restic
    rgb
    tailscale
    virtualization
    wol
  ];

  home-manager.users.${user} = {
    imports = with self.modules.homeManager; [
      ankama-launcher
      scape2011
      microbot
      office
      webos-dev-manager
      torrent
      signal
    ];

    my.ai-memory.serverUrl = "https://saradomin.osiris-fish.ts.net:8443";

    home.packages = with pkgs; [
      google-chrome
    ];

  };

  programs.chromium.enable = true;

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
    artcraft.filmcraft.enable = true;
    wol.interface = "enp12s0";
    rgb.color = config.my.colors.secondary;
    restic = {
      paths = [
        "/home/${user}/Documents"
        "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
        "/home/${user}/.runelite/screenshots"

      ];
    };
    hermes-agent.web = {
      enable = true;
      publicUrl = "https://zaros.osiris-fish.ts.net";
      restartTriggers = [ ../../secrets/hermes-web.yaml ];
      environmentFile = lib.mkIf config.my.hermes-agent.web.enable config.sops.secrets.hermes-web.path;
    };
  };

  sops.secrets.hermes-web = lib.mkIf config.my.hermes-agent.web.enable {
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
