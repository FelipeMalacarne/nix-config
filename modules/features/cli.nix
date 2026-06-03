let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = {
        home.packages = with pkgs; [
          ripgrep
          fd
          jq
          bat
          fastfetch
          zip
          unzip
          p7zip-rar
          gnumake
          wakeonlan
        ];

        programs.fzf = {
          enable = true;
          enableZshIntegration = true;
        };

        programs.eza = {
          enable = true;
          enableZshIntegration = true;
        };

        programs.zoxide = {
          enable = true;
          enableZshIntegration = true;
        };
      };
    };
in
{
  flake.nixosModules.cli = module;
  flake.darwinModules.cli = module;
}
