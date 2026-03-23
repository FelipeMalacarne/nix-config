# modules/nixos/network.nix
# Note: networking.networkmanager.enable is also a Noctalia system dep
# (per upstream docs) — intentionally placed here, not in desktop.nix
{ ... }:
{
  networking.hostName = "zaros";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
