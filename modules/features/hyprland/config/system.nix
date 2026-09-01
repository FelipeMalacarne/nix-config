{ ... }:
{
  flake.nixosModules.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions) {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
      home-manager.users.${config.my.user.name}.home.sessionVariables.HYPRLAND_LUA_STUBS =
        "${pkgs.hyprland}/share/hypr/stubs";
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };
    };
}
