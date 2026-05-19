{
  flake.nixosModules.network = {
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
  };
}
