{ inputs, ... }:
{
  flake.nixosModules.dolphin = { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = { config, ... }:
        let
          p = config.colorScheme.palette;
          toRgb = inputs.nix-colors.lib.conversions.hexToRGBString ",";
          mimeApplications = {
            "application/pdf" = "org.kde.okular.desktop";
            "application/x-pdf" = "org.kde.okular.desktop";
            "application/zip" = "org.kde.ark.desktop";
            "application/x-zip-compressed" = "org.kde.ark.desktop";
            "application/x-7z-compressed" = "org.kde.ark.desktop";
            "application/x-bzip2" = "org.kde.ark.desktop";
            "application/x-bzip-compressed-tar" = "org.kde.ark.desktop";
            "application/x-compressed-tar" = "org.kde.ark.desktop";
            "application/gzip" = "org.kde.ark.desktop";
            "application/vnd.rar" = "org.kde.ark.desktop";
            "application/x-rar" = "org.kde.ark.desktop";
            "application/x-rar-compressed" = "org.kde.ark.desktop";
            "application/x-tar" = "org.kde.ark.desktop";
            "application/x-xz" = "org.kde.ark.desktop";
            "application/x-xz-compressed-tar" = "org.kde.ark.desktop";
            "application/zstd" = "org.kde.ark.desktop";
            "application/x-zstd-compressed-tar" = "org.kde.ark.desktop";
            "image/jpeg" = "org.kde.gwenview.desktop";
            "image/png" = "org.kde.gwenview.desktop";
            "image/gif" = "org.kde.gwenview.desktop";
            "image/webp" = "org.kde.gwenview.desktop";
            "image/bmp" = "org.kde.gwenview.desktop";
            "image/tiff" = "org.kde.gwenview.desktop";
            "image/svg+xml" = "org.kde.gwenview.desktop";
            "video/mp4" = "mpv.desktop";
            "video/3gpp" = "mpv.desktop";
            "video/mpeg" = "mpv.desktop";
            "video/ogg" = "mpv.desktop";
            "video/quicktime" = "mpv.desktop";
            "video/webm" = "mpv.desktop";
            "video/x-flv" = "mpv.desktop";
            "video/x-m4v" = "mpv.desktop";
            "video/x-matroska" = "mpv.desktop";
            "video/x-msvideo" = "mpv.desktop";
            "video/x-ms-wmv" = "mpv.desktop";
          };
        in
        {
          home.packages = with pkgs; [
            kdePackages.dolphin
            kdePackages.konsole
            kdePackages.kio-extras
            kdePackages.plasma-integration
            kdePackages.ark
            kdePackages.gwenview
            kdePackages.kimageformats
            kdePackages.okular
            mpv
            swayimg
            kdePackages.kde-cli-tools
            kdePackages.kservice
            kdePackages.qtsvg
            kdePackages.breeze-icons
            unar
            unzip
            zip
            zstd
          ];

          xdg.mimeApps = {
            enable = true;
            associations.added = mimeApplications;
            defaultApplications = mimeApplications;
          };

          qt = {
            enable = true;
            platformTheme.name = "kde";
          };

          xdg.configFile."dolphinrc".text = ''
            [General]
            ShowSelectionToggle=false
          '';

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
    };
}
