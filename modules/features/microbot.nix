{
  flake.nixosModules.microbot =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
      browser = pkgs.chromium;
      jdk = pkgs.jdk;

      microbotAppImage = pkgs.appimageTools.wrapType2 rec {
        pname = "microbot-launcher";
        version = "3.2.8";

        src = pkgs.fetchurl {
          url = "https://files.microbot.cloud/releases/microbot-launcher/Microbot%20Launcher-${version}.AppImage";
          name = "${pname}-${version}.AppImage";
          hash = "sha256-uviA/7N/jgYrAjkC6pN02ygOA2QFo+Q/f/xU+qjTWOo=";
        };
      };

      microbotLauncher = pkgs.writeShellApplication {
        name = "microbot-launcher";
        runtimeInputs = [ jdk ];
        text = ''
          export JAVA_HOME="${jdk}"
          exec ${microbotAppImage}/bin/microbot-launcher "$@"
        '';
      };
    in
    {
      home-manager.users.${user} = {
        home.packages = [
          browser
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
    };
}
