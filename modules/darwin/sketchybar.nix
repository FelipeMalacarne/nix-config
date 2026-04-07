{ pkgs, ... }:

{
  services.sketchybar.enable = true;
  services.sketchybar.package = pkgs.sketchybar;
}
