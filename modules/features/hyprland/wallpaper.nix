# modules/features/hyprland/wallpaper.nix
#
# Configures hyprpaper with a per-theme wallpaper based on colorScheme.slug.
# Add wallpapers at: modules/features/hyprland/wallpapers/<colorScheme.slug>.png
# Reloads the wallpaper live via systemctl after each rebuild.
{ config, lib, ... }:
let
  slug = config.colorScheme.slug;
  wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/${slug}.png";
in
{
  home.file."Pictures/wallpapers/${slug}.png".source = ./wallpapers/${slug}.png;

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ wallpaper ];
      wallpaper = [ ",${wallpaper}" ];
      splash = false;
    };
  };

  home.activation.reloadWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /run/current-system/sw/bin/systemctl --user restart hyprpaper.service
  '';
}
