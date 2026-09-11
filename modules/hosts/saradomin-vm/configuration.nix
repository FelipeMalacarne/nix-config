{ self, ... }:
{
  flake.nixosModules."saradomin-vm" =
    { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        self.nixosModules.saradominVmHardware
        self.nixosModules.base
        self.nixosModules.sops
      ];

      networking.hostName = "saradomin-vm";
      my.openssh.enable = true;
      my.tailscale.enable = true;
      home-manager.users.${user}.imports = [ self.homeModules.linux-base ];
      system.stateVersion = "24.11";

      services.qemuGuest.enable = true;
      services.openssh.settings.PasswordAuthentication = true;

      users.users.${user}.openssh.authorizedKeys.keyFiles = [
        ../../../keys/zaros.pub
      ];

      virtualisation.vmVariant = {
        virtualisation.memorySize = 4096;
        virtualisation.cores = 2;
        virtualisation.diskSize = 20480;
      };
    };
}
