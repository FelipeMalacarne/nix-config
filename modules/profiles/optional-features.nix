{ self, ... }:
{
  flake.nixosModules.optional-features = {
    imports = with self.nixosModules; [
      docker
      flatpak
      gaming
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
