# modules/home/common/cli.nix
{ pkgs, ... }:
{
  # ripgrep has no Home Manager module — add directly to packages
  home.packages = with pkgs; [ ripgrep claude-code ];

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };
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
