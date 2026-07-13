{ ... }:
{
  flake.homeModules.sketchybar =
    { config, ... }:
    let
      p = config.lib.stylix.colors;
      source = ../../../assets/sketchybar;
    in
    {
      home.file.".config/sketchybar/colors.sh".text = ''
        #!/usr/bin/env bash
        export BLACK=0xff${p.base01}
        export WHITE=0xff${p.base05}
        export RED=0xff${p.base08}
        export GREEN=0xff${p.base0B}
        export BLUE=0xff${p.base0D}
        export YELLOW=0xff${p.base0A}
        export ORANGE=0xff${p.base09}
        export MAGENTA=0xff${p.base0E}
        export GREY=0xff${p.base04}
        export TRANSPARENT=0x00000000
        export BG0=0xff${p.base00}
        export BG1=0x60${p.base02}
        export BG2=0x60${p.base03}
        export BAR_COLOR=$BG0
        export BAR_BORDER_COLOR=$BG2
        export BACKGROUND_1=$BG1
        export BACKGROUND_2=$BG2
        export ICON_COLOR=$WHITE
        export LABEL_COLOR=$WHITE
        export POPUP_BACKGROUND_COLOR=$BAR_COLOR
        export POPUP_BORDER_COLOR=$WHITE
        export SHADOW_COLOR=$BLACK
      '';
      home.file.".config/sketchybar/sketchybarrc" = {
        source = source + "/sketchybarrc";
        executable = true;
      };
      home.file.".config/sketchybar/icons.sh".source = source + "/icons.sh";
      home.file.".config/sketchybar/items".source = source + "/items";
      home.file.".config/sketchybar/plugins".source = source + "/plugins";
      home.file.".config/sketchybar/helper".source = source + "/helper";
    };

  flake.darwinModules.sketchybar =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      services.sketchybar = {
        enable = true;
        package = pkgs.sketchybar;
      };

      fonts.packages = [ pkgs.sketchybar-app-font ];

    };
}
