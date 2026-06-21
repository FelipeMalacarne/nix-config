{ ... }:
{
  flake.nixosModules.sddm =
    { pkgs, ... }:
    {
      services.displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "${pkgs.catppuccin-sddm.override {
            background = ../../assets/wallpapers/catppuccin-mocha.png;
          }}/share/sddm/themes/catppuccin-mocha-mauve";
        };
        autoLogin.enable = false;
      };
    };
}
