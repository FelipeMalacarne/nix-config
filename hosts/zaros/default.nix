{
  config,
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
    hyprland
    umbriel
    noctalia
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
      toolchain-cloud
      toolchain-elixir
      toolchain-go
      toolchain-laravel
      toolchain-node
      toolchain-python
      artcraft
      scape2011
      microbot
      chronicle
      office
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
    rgb.color = config.lib.stylix.colors.withHashtag.base0E;
    restic = {
      paths = [
        "/home/${user}/Documents"
        "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
        "/home/${user}/.runelite/screenshots"

      ];
    };
  };

  system.stateVersion = "24.11";
}
