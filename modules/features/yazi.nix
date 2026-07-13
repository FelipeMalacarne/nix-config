{
  flake.homeModules.yazi =
    { pkgs, ... }:
    let
      yazi-launcher = pkgs.writeShellScript "yazi-launcher" ''
        exec $TERMINAL -e yazi
      '';
    in
    {
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
      };

      xdg.desktopEntries.yazi = {
        name = "Yazi";
        genericName = "File Manager";
        exec = "${yazi-launcher}";
        terminal = false;
        categories = [
          "System"
          "FileManager"
        ];
        icon = "yazi";
      };
    };
}
