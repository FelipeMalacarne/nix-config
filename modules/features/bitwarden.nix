# modules/features/bitwarden.nix
#
# Bitwarden desktop password manager.
# SSH agent socket used by features/ssh.nix for key authentication.
{ config, pkgs, ... }:
let
  user = config.my.user.name;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
