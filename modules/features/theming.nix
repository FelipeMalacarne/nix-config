{ inputs, ... }:
{
  flake.nixosModules.theming =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix.enable = true;
      stylix.polarity = "dark";
      stylix.image = ../../assets/wallpapers/catppuccin-mocha.png;
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      stylix.fonts = {
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
        emoji = {
          name = "Noto Color Emoji";
          package = pkgs.noto-fonts-color-emoji;
        };
      };

      environment.systemPackages = [ pkgs.nerd-fonts.symbols-only ];
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
