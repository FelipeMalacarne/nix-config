{
  flake.modules.homeManager.office = { pkgs, ... }: {
    home.packages = with pkgs; [
      libreoffice-stable
      hunspell
      hunspellDicts.pt_BR
      hunspellDicts.en_US
      zathura
    ];
  };
}
