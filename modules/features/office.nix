{
  flake.nixosModules.office =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user}.home.packages = with pkgs; [
        libreoffice-fresh
        hunspell
        hunspellDicts.pt_BR
        hunspellDicts.en_US
        zathura
      ];
    };
}
