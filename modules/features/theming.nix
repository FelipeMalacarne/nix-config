{ inputs, lib, ... }:
let
  colorNames = [
    "background"
    "surface"
    "surfaceAlt"
    "selection"
    "overlay"
    "foreground"
    "text"
    "textMuted"
    "textSubtle"
    "textBright"
    "textHighest"
    "subtle"
    "muted"
    "primary"
    "secondary"
    "accent"
    "special"
    "success"
    "warning"
    "error"
    "info"
    "red"
    "orange"
    "yellow"
    "green"
    "cyan"
    "blue"
    "purple"
    "shadow"
  ];
  colorContract = {
    options = lib.genAttrs colorNames (_: lib.mkOption { type = lib.types.str; });
  };
  palette = c: {
    background = "#${c.base00}";
    surface = "#${c.base01}";
    surfaceAlt = "#${c.base02}";
    selection = "#${c.base02}";
    overlay = "#${c.base03}";
    foreground = "#${c.base05}";
    text = "#${c.base05}";
    textMuted = "#${c.base04}";
    textSubtle = "#${c.base03}";
    textBright = "#${c.base06}";
    textHighest = "#${c.base07}";
    subtle = "#${c.base04}";
    muted = "#${c.base03}";
    primary = "#${c.base0D}";
    secondary = "#${c.base0E}";
    accent = "#${c.base0C}";
    special = "#${c.base0F}";
    success = "#${c.base0B}";
    warning = "#${c.base0A}";
    error = "#${c.base08}";
    info = "#${c.base0C}";
    red = "#${c.base08}";
    orange = "#${c.base09}";
    yellow = "#${c.base0A}";
    green = "#${c.base0B}";
    cyan = "#${c.base0C}";
    blue = "#${c.base0D}";
    purple = "#${c.base0E}";
    shadow = "#000000";
  };
in
{
  flake.nixosModules.theming =
    { config, pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      options.my.colors = lib.mkOption {
        type = lib.types.submodule colorContract;
        description = "Semantic color palette derived from the active stylix theme.";
      };

      config = {
        my.colors = palette config.lib.stylix.colors;
        stylix = {
          enable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
          opacity = {
            desktop = 0.93;
            popups = 1.0;
          };
          fonts = {
            emoji = {
              name = "Noto Color Emoji";
              package = pkgs.noto-fonts-color-emoji;
            };
            monospace = {
              name = "Fira Code Nerd Font Mono";
              package = pkgs.nerd-fonts.fira-code;
            };
            sansSerif = {
              name = "Noto Sans";
              package = pkgs.noto-fonts;
            };
            serif = {
              name = "Noto Serif";
              package = pkgs.noto-fonts;
            };
          };
          image = ../../assets/wallpapers/catppuccin-mocha.png;
          polarity = "dark";
        };
        environment.systemPackages = [ pkgs.nerd-fonts.symbols-only ];
      };
    };

  flake.darwinModules.theming =
    { config, pkgs, ... }:
    {
      imports = [ inputs.stylix.darwinModules.stylix ];

      options.my.colors = lib.mkOption {
        type = lib.types.submodule colorContract;
        description = "Semantic color palette derived from the active stylix theme.";
      };

      config = {
        my.colors = palette config.lib.stylix.colors;
        stylix = {
          enable = true;
          polarity = "dark";
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
          fonts = {
            emoji = {
              name = "Noto Color Emoji";
              package = pkgs.noto-fonts-color-emoji;
            };
            monospace = {
              name = "JetBrainsMono Nerd Font Mono";
              package = pkgs.nerd-fonts.jetbrains-mono;
            };
            sansSerif = {
              name = "Noto Sans";
              package = pkgs.noto-fonts;
            };
            serif = {
              name = "Noto Serif";
              package = pkgs.noto-fonts;
            };
          };
          image = ../../assets/wallpapers/catppuccin-mocha.png;
        };
        environment.systemPackages = [ pkgs.nerd-fonts.symbols-only ];
      };
    };
}
