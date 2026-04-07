# modules/home/desktop/wallpaper.nix
#
# Configures hyprpaper with a per-theme wallpaper based on colorScheme.slug.
# Add wallpapers at: modules/home/desktop/wallpapers/<colorScheme.slug>.png
{ config, ... }:
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
}
