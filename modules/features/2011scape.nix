{
  flake.homeModules.scape2011 =
    { pkgs, ... }:
    let
      version = "2025-02-11";

      src = pkgs.fetchurl {
        url = "https://2011.rs/downloads/linux/native-linux-x86_64/2011Scape.AppImage";
        name = "2011scape-${version}.AppImage";
        hash = "sha256-x8Kwek4H9gk1EU0XFH+nH7UbsCbyxMsyUQ0Op8VJPI4=";
      };

      runtimeLibs = with pkgs; [
        libX11
        libXext
        libXrender
        libXtst
        libXi
        libxcb
        libXau
        libXdmcp
        freetype
        fontconfig
      ];
      libPath = pkgs.lib.makeLibraryPath runtimeLibs;

      extracted = pkgs.appimageTools.extract {
        pname = "2011scape";
        inherit version src;
      };

      patchedJar = pkgs.stdenv.mkDerivation {
        pname = "2011scape-launcher";
        inherit version;
        src = "${extracted}/2011Scape.jar";
        nativeBuildInputs = [
          pkgs.unzip
          pkgs.zip
        ];
        dontUnpack = true;

        installPhase = ''
          runHook preInstall

          jarDir="$TMPDIR/2011scape-jar"
          mkdir -p "$jarDir" "$out"
          unzip -q "$src" -d "$jarDir"

          properties="$jarDir/net/runelite/launcher/launcher.properties"
          test -f "$properties"
          substituteInPlace "$properties" \
            --replace-fail 'runelite.main=RS2Loader' 'runelite.main=Loader'

          (cd "$jarDir" && zip -X -qr "$out/2011Scape.jar" .)

          runHook postInstall
        '';
      };

      launcher = pkgs.writeShellApplication {
        name = "2011scape";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          stateHome="$HOME/.local/share/2011scape-home"
          mkdir -p "$stateHome"
          export JAVA_TOOL_OPTIONS="-Duser.home=$stateHome''${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}"
          export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          exec ${extracted}/jre/bin/java \
            -jar ${patchedJar}/2011Scape.jar \
            --launch-mode REFLECT "$@"
        '';
      };
    in
    {
      home.packages = [ launcher ];

      xdg.desktopEntries."2011scape" = {
        name = "2011Scape";
        genericName = "RuneScape 2011 Client";
        exec = "${launcher}/bin/2011scape";
        terminal = false;
        categories = [ "Game" ];
      };
    };
}
