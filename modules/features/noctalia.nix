{ self, ... }:
{
  flake.nixosModules.noctalia = { pkgs, ... }: {
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    environment.systemPackages = [ self.packages.${pkgs.system}.noctalia ];
  };
}
