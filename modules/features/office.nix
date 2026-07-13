{
  flake.homeModules.office = { pkgs, ... }: {
    home.packages = with pkgs; [
      libreoffice-fresh
      hunspell
      hunspellDicts.pt_BR
      hunspellDicts.en_US
      zathura
    ];
  };
}
