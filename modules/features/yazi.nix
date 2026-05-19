# modules/features/yazi.nix
#
# Yazi file manager with shell wrapper and desktop entry that opens
# inside the configured terminal instead of relying on Terminal=true.
{ config, pkgs, ... }:
let
  user = config.my.user.name;
  yazi-launcher = pkgs.writeShellScript "yazi-launcher" ''
    exec $TERMINAL -e yazi
  '';
in
{
  home-manager.users.${user} = {
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
