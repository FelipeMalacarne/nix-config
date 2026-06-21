{ inputs, ... }:
{
  flake.nixosModules.dolphin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
    in
    {
      nixpkgs.overlays = [ inputs.dolphin-overlay.overlays.default ];

      home-manager.users.${user} =
        { config, lib, ... }:
        let
          p = config.lib.stylix.colors;
          rgb = n: "${p."${n}-rgb-r"},${p."${n}-rgb-g"},${p."${n}-rgb-b"}";
        in
        {
          home.packages = with pkgs; [
            kdePackages.kio
            kdePackages.kio-fuse
            kdePackages.kio-extras
            kdePackages.qtsvg
            kdePackages.ark
            kdePackages.breeze-icons
            kdePackages.dolphin
            kdePackages.gwenview
            kdePackages.okular
            kdePackages.plasma-integration
            kdePackages.kde-cli-tools
            mpv
            unar
            unzip
            zip
            zstd
          ];

          xdg.configFile."kdeglobals".text = ''
            [General]
            ColorScheme=NixGenerated
            TerminalApplication=alacritty
            TerminalService=Alacritty.desktop

            [KDE]
            SingleClick=false

            [Icons]
            Theme=breeze-dark

            [Colors:Window]
            BackgroundNormal=${rgb "base00"}
            BackgroundAlternate=${rgb "base01"}
            ForegroundNormal=${rgb "base05"}
            ForegroundInactive=${rgb "base03"}
            ForegroundNegative=${rgb "base08"}
            ForegroundPositive=${rgb "base0B"}
            ForegroundLink=${rgb "base0C"}
            DecorationFocus=${rgb "base0D"}
            DecorationHover=${rgb "base0E"}

            [Colors:Button]
            BackgroundNormal=${rgb "base00"}
            BackgroundAlternate=${rgb "base01"}
            ForegroundNormal=${rgb "base05"}
            ForegroundInactive=${rgb "base03"}
            ForegroundNegative=${rgb "base08"}
            ForegroundPositive=${rgb "base0B"}
            ForegroundLink=${rgb "base0C"}
            DecorationFocus=${rgb "base0D"}
            DecorationHover=${rgb "base0E"}

            [Colors:View]
            BackgroundNormal=${rgb "base00"}
            BackgroundAlternate=${rgb "base01"}
            ForegroundNormal=${rgb "base05"}
            ForegroundInactive=${rgb "base03"}
            ForegroundNegative=${rgb "base08"}
            ForegroundPositive=${rgb "base0B"}
            ForegroundLink=${rgb "base0C"}
            DecorationFocus=${rgb "base0D"}
            DecorationHover=${rgb "base0E"}

            [Colors:Selection]
            BackgroundNormal=${rgb "base02"}
            ForegroundNormal=${rgb "base05"}
            DecorationFocus=${rgb "base0D"}
            DecorationHover=${rgb "base0E"}

            [Colors:Tooltip]
            BackgroundNormal=${rgb "base01"}
            ForegroundNormal=${rgb "base05"}
          '';
        };
    };
}
