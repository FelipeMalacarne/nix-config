{ inputs, ... }:
{
  flake.modules.nixos.theming =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      config = {
        stylix = {
          enable = true;
          base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-mocha.yaml";
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
            sizes.terminal = 11;
            sansSerif = {
              name = "Noto Sans";
              package = pkgs.noto-fonts;
            };
            serif = {
              name = "Noto Serif";
              package = pkgs.noto-fonts;
            };
          };
          image = ./config/catppuccin-mocha.png;
          polarity = "dark";
        };
        environment.systemPackages = [ pkgs.nerd-fonts.symbols-only ];
      };
    };

  flake.modules.darwin.theming =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.darwinModules.stylix ];

      config = {
        stylix = {
          enable = true;
          polarity = "dark";
          base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-mocha.yaml";
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
          image = ./config/catppuccin-mocha.png;
        };
        environment.systemPackages = [ pkgs.nerd-fonts.symbols-only ];
      };
    };
}
