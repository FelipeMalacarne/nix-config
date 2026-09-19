{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.optional-features = {
    imports = with registry.nixos; [
      adguard-home
      docker
      flatpak
      gaming
      hermes-agent
      k3s
      nvidia
      ollama
      openssh
      restic
      rgb
      sunshine
      tailscale
      virtualization
    ];
  };
}
