# modules/home/common/git.nix
{ ... }:
{
  programs.git = {
    enable = true;
    userName = "FelipeMalacarne";
    userEmail = "felipemalacarne012@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
