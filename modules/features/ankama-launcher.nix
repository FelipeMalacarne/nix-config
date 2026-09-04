{
  flake.homeModules.ankama-launcher =
    { lib, pkgs, ... }:
    let
      pname = "ankama-launcher";
      version = "3.15.2";

      src = pkgs.fetchurl {
        url = "https://web.archive.org/web/20260804211629/https://launcher.cdn.ankama.com/installers/production/Ankama%20Launcher-Setup-x86_64.AppImage";
        name = "${pname}-${version}.AppImage";
        hash = "sha256-0JJCTEpiGABy8yetwdZpGdxR0vwLBFY9ktdDp9fNKr4=";
      };

      appimageContents = pkgs.appimageTools.extract {
        inherit pname version src;

        postExtract = ''
          appAsar="$out/resources/app.asar"
          chmod u+w "$appAsar"

          old='autoupdaterUrl:"https://launcher.cdn.ankama.com/installers"'
          prefix='autoupdaterUrl:""'
          printf -v padding '%*s' "$(( ''${#old} - ''${#prefix} - 4 ))" ""
          new="$prefix/*$padding*/"
          sizeBefore=$(stat -c %s "$appAsar")

          test "''${#old}" -eq "''${#new}"
          OLD="$old" NEW="$new" ${pkgs.perl}/bin/perl -0777 -pi -e \
            's/\Q$ENV{"OLD"}\E/$ENV{"NEW"}/g or die "updater URL not found\n"' \
            "$appAsar"
          OLD="$old" ${pkgs.perl}/bin/perl -0777 -ne \
            'index($_, $ENV{"OLD"}) < 0 or die "updater URL remains\n"' \
            "$appAsar"
          test "$(stat -c %s "$appAsar")" -eq "$sizeBefore"
        '';
      };

      launcher = pkgs.appimageTools.wrapAppImage {
        inherit pname version;
        src = appimageContents;
        extraPkgs = pkgs: [ pkgs.wine ];

        extraInstallCommands = ''
          install -m 444 -D ${appimageContents}/zaap.desktop \
            $out/share/applications/ankama-launcher.desktop
          substituteInPlace $out/share/applications/ankama-launcher.desktop \
            --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=ankama-launcher %U'
          install -m 444 -D ${appimageContents}/zaap.png \
            $out/share/icons/hicolor/256x256/apps/zaap.png
        '';

        meta = {
          description = "Ankama Launcher";
          homepage = "https://www.ankama.com/en/launcher";
          license = lib.licenses.unfree;
          mainProgram = "ankama-launcher";
          platforms = [ "x86_64-linux" ];
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      };
    in
    {
      home.packages = [ launcher ];
    };
}
