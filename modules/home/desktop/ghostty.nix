# modules/home/desktop/ghostty.nix
{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 13;
      shell-integration = "zsh";
      window-decoration = false; # Hyprland handles decorations
      background-opacity = 0.95;

      # Catppuccin Mocha — basic colors to match Noctalia theme
      background = "1e1e2e";
      foreground = "cdd6f4";
      cursor-color = "f5e0dc";
      selection-background = "313244";
      selection-foreground = "cdd6f4";
    };
  };
}
