# modules/home/desktop/yazi.nix
#
# Desktop integration for yazi — overrides the nixpkgs desktop entry so
# launchers open it inside the configured terminal instead of relying on
# Terminal=true behaviour.
{ pkgs, ... }:
let
  yazi-launcher = pkgs.writeShellScript "yazi-launcher" ''
    exec $TERMINAL -e yazi
  '';
in
{
  xdg.desktopEntries.yazi = {
    name = "Yazi";
    genericName = "File Manager";
    exec = "${yazi-launcher}";
    terminal = false;
    categories = [ "System" "FileManager" ];
    icon = "yazi";
  };
}
