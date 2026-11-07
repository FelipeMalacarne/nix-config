{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.homeManager.microbot =
    { pkgs, ... }:
    let
      jdk = pkgs.jdk;

      microbotAppImage = pkgs.appimageTools.wrapType2 rec {
        pname = "microbot-launcher";
        version = "3.2.28";

        src = pkgs.fetchurl {
          url = "https://files.microbot.cloud/releases/microbot-launcher/Microbot%20Launcher-${version}.AppImage";
          name = "${pname}-${version}.AppImage";
          hash = "sha256-2xo2OGcKikP7wkDz+9KNMvLyrNwjSam9/RxwkwhsQOs=";
        };
      };

      microbotLauncher = pkgs.writeShellApplication {
        name = "microbot-launcher";
        runtimeInputs = [
          jdk
          pkgs.coreutils
        ];
        text = ''
          export JAVA_HOME="${jdk}"

          # Microbot deletes non-Hub plugin jars older than 3 days. Keep the ones that
          # microbot-plugins' `mb-install --live` listed in .sideload-keep.
          plugins="$HOME/.runelite/microbot-plugins"
          if [[ -f "$plugins/.sideload-keep" ]]; then
            while IFS= read -r jar; do
              if [[ -n "$jar" && -f "$plugins/$jar" ]]; then
                touch "$plugins/$jar"
              fi
            done <"$plugins/.sideload-keep"
          fi

          exec ${microbotAppImage}/bin/microbot-launcher "$@"
        '';
      };
    in
    {
      # Chromium on PATH comes from the shared agent-browser feature.
      imports = [ registry.homeManager.chromium ];

      home.packages = [
        jdk
        microbotLauncher
      ];

      xdg.desktopEntries.microbot-launcher = {
        name = "Microbot Launcher";
        genericName = "Game Launcher";
        exec = "${microbotLauncher}/bin/microbot-launcher";
        terminal = false;
        categories = [ "Game" ];
      };
    };
}
