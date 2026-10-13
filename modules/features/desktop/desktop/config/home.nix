{
  config,
  lib,
  pkgs,
  ...
}:
let
  sessionVariables = {
    GTK_IM_MODULE = "simple";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "22";
    XCOMPOSEFILE = "${config.home.homeDirectory}/.XCompose";
  };
in
{
  config =
    lib.mkIf
      (lib.any (session: builtins.elem session config.my.desktop.sessions) [
        "hyprland"
        "umbriel"
      ])
      {
        home.file.".XCompose".text = ''
          include "%L"
          <dead_acute> <c> : "ç" ccedilla
          <dead_acute> <C> : "Ç" Ccedilla
        '';
        dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
        home.pointerCursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 16;
          gtk.enable = true;
          x11.enable = true;
        };
        home.sessionVariables = sessionVariables;
        systemd.user.sessionVariables = sessionVariables;
      };
}
