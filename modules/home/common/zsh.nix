# modules/home/common/zsh.nix
{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = {
      sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
