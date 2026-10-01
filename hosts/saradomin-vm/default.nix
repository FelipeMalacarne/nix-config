{ config, self, ... }:
let
  user = config.my.user.name;
in
{
  imports = with self.modules.nixos; [
    ./hardware.nix
    server
    openssh
    tailscale
  ];

  networking.hostName = "saradomin-vm";
  system.stateVersion = "24.11";

  services.qemuGuest.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
  ];

  virtualisation.vmVariant = {
    virtualisation.memorySize = 4096;
    virtualisation.cores = 2;
    virtualisation.diskSize = 20480;
  };
}
