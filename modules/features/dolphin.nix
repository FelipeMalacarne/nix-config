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
      imageTypes = [
        "image/jpeg"
        "image/png"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
      ];
      archiveTypes = [
        "application/gzip"
        "application/vnd.rar"
        "application/zip"
        "application/zstd"
        "application/x-7z-compressed"
        "application/x-bzip2"
        "application/x-bzip-compressed-tar"
        "application/x-compressed-tar"
        "application/x-rar"
        "application/x-rar-compressed"
        "application/x-tar"
        "application/x-xz"
        "application/x-xz-compressed-tar"
        "application/x-zip-compressed"
        "application/x-zstd-compressed-tar"
      ];
      videoTypes = [
        "video/3gpp"
        "video/mp4"
        "video/mpeg"
        "video/ogg"
        "video/quicktime"
        "video/webm"
        "video/x-flv"
        "video/x-m4v"
        "video/x-matroska"
        "video/x-ms-wmv"
        "video/x-msvideo"
      ];
      defaultApplications = {
        "application/pdf" = "okularApplication_pdf.desktop";
        "application/x-pdf" = "okularApplication_pdf.desktop";
      }
      // lib.genAttrs imageTypes (_: "org.kde.gwenview.desktop")
      // lib.genAttrs archiveTypes (_: "org.kde.ark.desktop")
      // lib.genAttrs videoTypes (_: "mpv.desktop");
    in
    {
      home-manager.users.${user} =
        { config, lib, ... }:
        let
          p = config.lib.stylix.colors;
          rgb = n: "${p."${n}-rgb-r"},${p."${n}-rgb-g"},${p."${n}-rgb-b"}";
        in
        {
          home.packages = with pkgs; [
            kdePackages.ark
            kdePackages.breeze-icons
            kdePackages.dolphin
            kdePackages.gwenview
            kdePackages.kde-cli-tools
            kdePackages.kimageformats
            kdePackages.kio-extras
            kdePackages.kservice
            kdePackages.okular
            kdePackages.plasma-integration
            kdePackages.qtsvg
            mpv
            unar
            unzip
            zip
            zstd
          ];

          xdg.mimeApps = {
            enable = true;
            associations.added = defaultApplications;
            inherit defaultApplications;
          };

          home.activation.rebuildKServiceCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
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
