{ self, ... }:
{
  imports = with self.modules.nixos; [
    ./hardware.nix
    server
    ssh-credentials
    openssh
    tailscale
  ];

  networking.hostName = "saradomin-vm";
  system.stateVersion = "24.11";

  services.qemuGuest.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  my.infrastructure.ssh.authorizedKeys = [ ../../keys/zaros.pub ];

  virtualisation.vmVariant = {
    virtualisation.memorySize = 4096;
    virtualisation.cores = 2;
    virtualisation.diskSize = 20480;
  };
}
