{ lib }:
host:
builtins.attrNames (
  lib.filterAttrs (_: enabled: enabled) {
    adguard-home = host.services.adguardhome.enable;
    docker = host.virtualisation.docker.enable;
    flatpak = host.services.flatpak.enable;
    gaming = host.programs.steam.enable;
    hermes-agent = host.home-manager.users.${host.my.user.name}.programs.hermes-agent.enable or false;
    k3s = host.services.k3s.enable;
    nvidia = builtins.elem "nvidia" host.services.xserver.videoDrivers;
    ollama = host.services.ollama.enable;
    openssh = host.services.openssh.enable;
    restic = host.services.restic.backups ? r2;
    rgb = host.services.hardware.openrgb.enable;
    sunshine = host.services.sunshine.enable;
    tailscale = host.services.tailscale.enable;
    virtualization = host.virtualisation.libvirtd.enable;
    wol = host.systemd.services ? enable-wol;
  }
)
