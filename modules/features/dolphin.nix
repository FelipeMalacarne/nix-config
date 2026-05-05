# modules/features/dolphin.nix
#
# KDE Dolphin file manager with nix-colors theming and swayimg for images.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = config.myConfig.primaryUser;
in
{
  home-manager.users.${user} =
    { config, ... }:
    let
      p = config.colorScheme.palette;
      toRgb = inputs.nix-colors.lib.conversions.hexToRGBString ",";
    in
    {
      home.packages = with pkgs; [
        kdePackages.dolphin
        kdePackages.kio-extras
        swayimg
        kdePackages.kde-cli-tools
        kdePackages.qtsvg
        kdePackages.breeze-icons
      ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/jpeg" = "swayimg.desktop";
          "image/png" = "swayimg.desktop";
          "image/gif" = "swayimg.desktop";
          "image/webp" = "swayimg.desktop";
          "image/bmp" = "swayimg.desktop";
          "image/tiff" = "swayimg.desktop";
          "image/svg+xml" = "swayimg.desktop";
        };
      };

      qt = {
        enable = true;
        platformTheme.name = "kde";
      };

      xdg.configFile."kdeglobals".text = ''
        [General]
        ColorScheme=NixGenerated

        [Icons]
        Theme=breeze-dark

        [Colors:Window]
        BackgroundNormal=${toRgb p.base00}
        BackgroundAlternate=${toRgb p.base01}
        ForegroundNormal=${toRgb p.base05}
        ForegroundInactive=${toRgb p.base03}
        ForegroundNegative=${toRgb p.base08}
        ForegroundPositive=${toRgb p.base0B}
        ForegroundLink=${toRgb p.base0C}
        DecorationFocus=${toRgb p.base0D}
        DecorationHover=${toRgb p.base0E}

        [Colors:Button]
        BackgroundNormal=${toRgb p.base00}
        BackgroundAlternate=${toRgb p.base01}
        ForegroundNormal=${toRgb p.base05}
        ForegroundInactive=${toRgb p.base03}
        ForegroundNegative=${toRgb p.base08}
        ForegroundPositive=${toRgb p.base0B}
        ForegroundLink=${toRgb p.base0C}
        DecorationFocus=${toRgb p.base0D}
        DecorationHover=${toRgb p.base0E}

        [Colors:View]
        BackgroundNormal=${toRgb p.base00}
        BackgroundAlternate=${toRgb p.base01}
        ForegroundNormal=${toRgb p.base05}
        ForegroundInactive=${toRgb p.base03}
        ForegroundNegative=${toRgb p.base08}
        ForegroundPositive=${toRgb p.base0B}
        ForegroundLink=${toRgb p.base0C}
        DecorationFocus=${toRgb p.base0D}
        DecorationHover=${toRgb p.base0E}

        [Colors:Selection]
        BackgroundNormal=${toRgb p.base02}
        ForegroundNormal=${toRgb p.base05}
        DecorationFocus=${toRgb p.base0D}
        DecorationHover=${toRgb p.base0E}

        [Colors:Tooltip]
        BackgroundNormal=${toRgb p.base01}
        ForegroundNormal=${toRgb p.base05}
      '';
    };
}
