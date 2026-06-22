{ ... }:
{
  flake.nixosModules.sddm =
    { lib, pkgs, ... }:
    {
      services.xserver.enable = true;

      services.displayManager = {
        sddm = {
          enable = true;
          wayland.enable = false;
          theme = "${
            pkgs.catppuccin-sddm.override {
              background = ../../assets/wallpapers/catppuccin-mocha.png;
            }
          }/share/sddm/themes/catppuccin-mocha-mauve";
          setupScript = ''
            ${lib.getExe pkgs.xrandr} \
              --output DP-1 --primary --mode 2560x1440 --rate 239.76 --pos 0x0 \
              --output HDMI-A-1 --mode 2560x1440 --rate 74.97 --pos 2560x0
          '';
          settings = {
            Theme = {
              CursorTheme = "Bibata-Modern-Classic";
              CursorSize = "22";
            };
          };
        };
        autoLogin.enable = false;
      };

      environment.systemPackages = [ pkgs.bibata-cursors ];

      environment.etc."share/wayland-sessions/hyprland.desktop".enable = lib.mkForce false;
    };
}
