{ config, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    pkgs.waybar
    pkgs.dunst
    libnotify
    kitty
    swww
    rofi-wayland

    (pkgs.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      })
    )
  ];

  hardware = {
      opengl.enable = true;

      nvidia.modesetting.enable = true;
  };

  services.xserver = {
      enable = true;
      displayManager.gdm = {
          enable = true;
          wayland = true;
      };
  };
}
