# modules/home/desktop/wallpaper.nix
#
# Configures hyprpaper with a per-theme wallpaper based on colorScheme.slug.
# Add wallpapers at: modules/home/desktop/wallpapers/<colorScheme.slug>.png
# The activation step reloads the wallpaper live via hyprpaper IPC after each rebuild.
{ lib, config, ... }:
let
  slug      = config.colorScheme.slug;
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

  # Restart hyprpaper after every rebuild so the new wallpaper is applied immediately.
  # Using systemctl instead of hyprctl IPC because HYPRLAND_INSTANCE_SIGNATURE
  # is not available in the home-manager activation environment.
  home.activation.reloadWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /run/current-system/sw/bin/systemctl --user restart hyprpaper.service
  '';
}
