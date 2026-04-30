# modules/features/network.nix
#
# NetworkManager + firewall. Hostname is set per-host.
# Note: networkmanager.enable is also a Noctalia system dependency.
{ ... }:
{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
