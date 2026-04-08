# modules/home/desktop/yazi.nix
#
# Desktop integration for yazi — overrides the nixpkgs desktop entry so
# launchers open it inside the configured terminal instead of relying on
# Terminal=true behaviour.
{ config, ... }:
{
  xdg.desktopEntries.yazi = {
    name        = "Yazi";
    genericName = "File Manager";
    exec        = "${config.desktop.terminal.name} -e yazi";
    terminal    = false;
    categories  = [ "System" "FileManager" ];
    icon        = "yazi";
  };
}
