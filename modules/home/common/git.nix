# modules/home/common/git.nix
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "FelipeMalacarne";
      user.email = "felipemalacarne012@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      gpg.format = null; # silence signing.format deprecation warning
    };
  };
}
