
{ config, pkgs, inputs, ... }:
{


  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "astronaut";
      settings.Theme.CursorTheme = "Bibata-Modern-Classic";
    };
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkb ={
        variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}
