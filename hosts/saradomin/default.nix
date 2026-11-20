{ self, ... }:
{
  imports = with self.modules.nixos; [
    ./disk.nix
    ./hardware.nix
    ./settings.nix
    # profiles
    server
    ai
    # shell
    ssh-credentials
    # services
    adguard-home
    k3s
    openssh
    tailscale
    # system
    internal-ca
  ];
}
