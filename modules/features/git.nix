# modules/features/git.nix
{ config, ... }:
let
  user = config.my.user.name;
in
{
  home-manager.users.${user} = {
    programs.git = {
      enable = true;
      signing.format = null; # adopt new default, silence deprecation warning
      settings = {
        user.name = "FelipeMalacarne";
        user.email = "felipemalacarne012@gmail.com";
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };
}
