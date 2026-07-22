{
  flake.homeModules.microbot =
    { pkgs, ... }:
    let
      browser = pkgs.chromium;
      jdk = pkgs.jdk;

      microbotAppImage = pkgs.appimageTools.wrapType2 rec {
        pname = "microbot-launcher";
        version = "3.2.8";

        src = pkgs.fetchurl {
          url = "https://files.microbot.cloud/releases/microbot-launcher/Microbot%20Launcher-${version}.AppImage";
          name = "${pname}-${version}.AppImage";
          hash = "sha256-5Vk5mE73pKMZ/4ic4mmJYvmBA2ZXKL7M1JFQ4eiRZls=";
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
}
