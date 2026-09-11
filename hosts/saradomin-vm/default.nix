{ config, self, ... }:
let
  user = config.my.user.name;
in
{
  imports = [
    ./hardware.nix
    self.modules.nixos.server
  ];

  networking.hostName = "saradomin-vm";
  my.openssh.enable = true;
  my.tailscale.enable = true;
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
