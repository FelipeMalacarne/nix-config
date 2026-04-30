{ config, inputs, ... }:
let
  p = inputs.nix-colors.colorSchemes.${config.myConfig.colorScheme}.palette;
in
{
  services.jankyborders = {
    enable = true;
    active_color = "0xff${p.base0B}";
    inactive_color = "0x60${p.base02}";
    width = 8.0;
  };
}
