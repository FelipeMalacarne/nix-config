# modules/home/desktop/noctalia.nix
#
# Catppuccin Mocha palette mapped to Material 3 color tokens.
# Palette reference: https://github.com/catppuccin/catppuccin#-palette
#
# IMPORTANT: Verify the homeModules attribute name before applying:
#   nix flake show github:noctalia-dev/noctalia-shell
# Update the import below if it differs from homeModules.default
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;

    colors = {
      # === Surface / Background colors ===
      # base: main background
      # surface: slightly elevated surfaces (cards, containers)
      # surface-variant: alternative surface
      base = "#1e1e2e"; # Catppuccin Mocha base
      surface = "#313244"; # Catppuccin Mocha surface0
      "surface-variant" = "#45475a"; # Catppuccin Mocha surface1

      # === Accent colors (Material 3 roles) ===
      primary = "#cba6f7"; # mauve — main brand color
      "on-primary" = "#1e1e2e"; # text on primary
      "primary-container" = "#45475a"; # surface1 — container for primary
      "on-primary-container" = "#cba6f7"; # primary text in container

      secondary = "#89b4fa"; # blue
      "on-secondary" = "#1e1e2e";
      "secondary-container" = "#313244";
      "on-secondary-container" = "#89b4fa";

      tertiary = "#a6e3a1"; # green
      "on-tertiary" = "#1e1e2e";
      "tertiary-container" = "#313244";
      "on-tertiary-container" = "#a6e3a1";

      error = "#f38ba8"; # red
      "on-error" = "#1e1e2e";
      "error-container" = "#45475a";
      "on-error-container" = "#f38ba8";

      # === Text / On-surface colors ===
      "on-surface" = "#cdd6f4"; # Catppuccin Mocha text
      "on-surface-variant" = "#bac2de"; # subtext1

      # === Outline / Border colors ===
      outline = "#6c7086"; # overlay0
      "outline-variant" = "#45475a"; # surface1

      # === Background ===
      background = "#1e1e2e";
      "on-background" = "#cdd6f4";

      # === Inverse colors (for snackbars, tooltips) ===
      "inverse-surface" = "#cdd6f4";
      "inverse-on-surface" = "#1e1e2e";
      "inverse-primary" = "#6c3483"; # darker mauve
    };
  };
}
