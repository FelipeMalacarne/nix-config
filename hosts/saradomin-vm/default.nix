{ self, ... }:
{
  imports = with self.modules.nixos; [
    ./hardware.nix
    ./settings.nix
    # profiles
    server
    # shell
    ssh-credentials
    # services
    openssh
    tailscale
  ];
}
