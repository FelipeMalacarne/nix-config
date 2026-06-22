{ ... }:
{
  flake.nixosModules.sddm =
    { lib, pkgs, ... }:
    {
      services.displayManager = {
        sddm = {
          enable = true;
          wayland = {
            enable = true;
            compositor = "kwin";
          };
          theme = "${
            pkgs.catppuccin-sddm.override {
              background = ../../assets/wallpapers/catppuccin-mocha.png;
            }
          }/share/sddm/themes/catppuccin-mocha-mauve";
          settings = {
            Theme = {
              CursorTheme = "Bibata-Modern-Classic";
              CursorSize = "22";
            };
          };
          extraPackages = [ pkgs.bibata-cursors ];
        };
        autoLogin.enable = false;
      };

      environment.etc."share/wayland-sessions/hyprland.desktop".enable = lib.mkForce false;
    };
}
