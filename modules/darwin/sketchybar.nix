{ pkgs, ... }:

{
  services.sketchybar.enable = true;
  services.sketchybar.package = pkgs.sketchybar;

  fonts.packages = with pkgs; [
      sketchybar-app-font
    ];
}
