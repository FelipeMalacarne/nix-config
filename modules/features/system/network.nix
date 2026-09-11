{
  flake.modules.nixos.network = {
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
  };
}
