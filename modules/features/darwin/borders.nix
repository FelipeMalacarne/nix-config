{ ... }:
{
  flake.darwinModules.borders = { config, lib, ... }: {
    services.jankyborders = {
      enable = true;
      active_color = lib.mkForce "0xff${config.lib.stylix.colors.base0B}";
      inactive_color = lib.mkForce "0x60${config.lib.stylix.colors.base02}";
      width = 8.0;
    };
  };
}
