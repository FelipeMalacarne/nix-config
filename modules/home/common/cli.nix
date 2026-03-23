# modules/home/common/cli.nix
{ pkgs, ... }:
{
  # ripgrep has no Home Manager module — add directly to packages
  home.packages = [ pkgs.ripgrep ];

  programs.yazi.enable = true;
  programs.btop.enable = true;
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
}
