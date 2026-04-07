# modules/home/desktop/dolphin.nix
{ inputs, config, pkgs, ... }:
let
  p = config.colorScheme.palette;
  toRgb = inputs.nix-colors.lib.conversions.hexToRGBString ",";
in
{
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.qtsvg
    kdePackages.breeze-icons
  ];

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
}
