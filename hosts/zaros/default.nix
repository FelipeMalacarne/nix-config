{ config, self, ... }:
{
  imports = with self.modules.nixos; [
    ./hardware.nix
    ./settings.nix
    # profiles
    base
    desktop
    development
    ai
    # shell
    ssh-credentials
    # dev
    docker
    programming-credentials
    k8s-credentials
    # ai
    claude-remote-control
    # desktop
    hyprland
    umbriel
    noctalia
    noctalia-greeter
    ./desktop.nix
    # apps
    chronicle-agent
    recording
    # games
    gaming
    # services
    ollama
    openssh
    restic
    tailscale
    wol
    # system
    flatpak
    internal-ca
    nvidia
    rgb
    virtualization
  ];

  home-manager.users.${config.my.user.name}.imports = with self.modules.homeManager; [
    # dev
    toolchain-cloud
    toolchain-elixir
    toolchain-go
    toolchain-laravel
    toolchain-node
    toolchain-python
    # ai
    linear-context-skill
    wayfinder-skills
    # apps
    artcraft
    chronicle
    office
    webapps
    webos-dev-manager
    torrent
    signal
    # games
    scape2011
    microbot
  ];
}
