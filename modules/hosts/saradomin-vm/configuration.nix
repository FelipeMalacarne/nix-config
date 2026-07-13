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
        self.nixosModules.identity
        self.nixosModules.core
        self.nixosModules.theming
        self.nixosModules.zsh
        self.nixosModules.ssh
        self.nixosModules.sops
        self.nixosModules.openssh
        self.nixosModules.tailscale
      ];

      networking.hostName = "saradomin-vm";
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
