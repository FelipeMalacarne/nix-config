# modules/features/office.nix
#
# Office suite and document tools: LibreOffice with spell checking
# and Zathura for PDF/document viewing.
{ config, pkgs, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      libreoffice-fresh
      hunspell
      hunspellDicts.pt_BR
      hunspellDicts.en_US
      zathura
    ];
  };
}
