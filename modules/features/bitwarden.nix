# modules/features/bitwarden.nix
#
# Bitwarden desktop password manager.
# SSH agent socket used by features/ssh.nix for key authentication.
{ config, pkgs, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
