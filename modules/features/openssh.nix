# modules/features/openssh.nix
#
# OpenSSH server — secure, no root login, firewall opened.
{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings.PermitRootLogin = "no";
  };
}
