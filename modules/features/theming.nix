{ inputs, ... }:
{
  flake.nixosModules.theming =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      options.my.colors = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "Semantic color palette derived from the active stylix theme.";
      };

      config = {
        my.colors =
          let
            c = config.lib.stylix.colors;
          in
          {
            # Base UI surfaces
            background = "#${c.base00}";
            surface = "#${c.base01}";
            surfaceAlt = "#${c.base02}";
            selection = "#${c.base02}";
            overlay = "#${c.base03}";

            # Text / foreground
            foreground = "#${c.base05}";
            text = "#${c.base05}";
            textMuted = "#${c.base04}";
            textSubtle = "#${c.base03}";
            textBright = "#${c.base06}";
            textHighest = "#${c.base07}";
            subtle = "#${c.base04}";
            muted = "#${c.base03}";

            # Semantic theme roles
            primary = "#${c.base0D}";
            secondary = "#${c.base0E}";
            accent = "#${c.base0C}";
            special = "#${c.base0F}";
            success = "#${c.base0B}";
            warning = "#${c.base0A}";
            error = "#${c.base08}";
            info = "#${c.base0C}";

            # Familiar Base16 color aliases
            red = "#${c.base08}";
            orange = "#${c.base09}";
            yellow = "#${c.base0A}";
            green = "#${c.base0B}";
            cyan = "#${c.base0C}";
            blue = "#${c.base0D}";
            purple = "#${c.base0E}";

            # Extra
            shadow = "#000000";
          };

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
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.darwinModules.stylix ];

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
}
