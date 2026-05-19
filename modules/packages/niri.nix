{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          input.keyboard = {
            xkb.layout = "us";
            xkb.variant = "intl";
          };

          layout.gaps = 5;

          binds = {
            "Mod+Return".spawn = lib.getExe pkgs.kitty;
            "Mod+W".close-window = { };
          };
        };
      };
    };
}
