{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    env = [
      "NVD_BACKEND,direct"
      "LIBVA_DRIVER_NAME,nvidia"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "GDK_SCALE,1"
      "XCURSOR_SIZE,24"
      "TERMINAL,alacritty"
    ];
  };
}
