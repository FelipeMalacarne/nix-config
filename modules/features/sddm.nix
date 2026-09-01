{ ... }:
{
  flake.nixosModules.sddm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      rotation =
        output:
        if output.rotation == 90 then
          "left"
        else if output.rotation == 180 then
          "inverted"
        else if output.rotation == 270 then
          "right"
        else
          "normal";
      xrandrOutputs = lib.concatMapStringsSep " \\\n           " (
        output:
        "--output ${output.match.xrandrOutput}"
        + lib.optionalString (output.role == "primary") " --primary"
        + " --mode ${toString output.mode.width}x${toString output.mode.height}"
        + " --rate ${toString output.mode.refresh}"
        + " --pos ${toString output.position.x}x${toString output.position.y}"
        + " --rotate ${rotation output}"
      ) (lib.attrValues config.my.desktop.monitors);
    in
    {
      services.xserver.enable = true;

      services.displayManager = {
        sddm = {
          enable = true;
          wayland.enable = false;
          setupScript = "${lib.getExe pkgs.xrandr} \\\n           ${xrandrOutputs}";
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
        };
        autoLogin.enable = false;
      };

      environment.systemPackages = [ pkgs.bibata-cursors ];

    };
}
