{ withSystem, ... }:
let
  source = ../../../../assets/sketchybar;
in
{
  perSystem =
    { lib, pkgs, ... }:
    let
      helper = pkgs.callPackage ./sketchybar/config/helper.nix { source = source + "/helper"; };
    in
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        sketchybar-helper = helper;
      };
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        sketchybar-helper = pkgs.runCommand "sketchybar-helper-check" { } ''
          ${pkgs.bash}/bin/bash -n ${source}/sketchybarrc
          if ${lib.getExe helper} > usage 2>&1; then
            echo 'The helper must reject invocation without a bootstrap name.' >&2
            exit 1
          fi
          ${pkgs.gnugrep}/bin/grep -F 'Usage: helper' usage
          if ${pkgs.gnugrep}/bin/grep -E '(^|[[:space:]])make([[:space:]]|$)' ${source}/sketchybarrc; then
            echo 'SketchyBar must not compile its helper at startup.' >&2
            exit 1
          fi
          touch "$out"
        '';
      };
    };

  flake.modules.homeManager.sketchybar =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      p = config.lib.stylix.colors;
      helper = withSystem pkgs.stdenv.hostPlatform.system (
        { config, ... }: config.packages.sketchybar-helper
      );
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
        source = pkgs.replaceVars (source + "/sketchybarrc") {
          SKETCHYBAR_HELPER = lib.getExe helper;
        };
        executable = true;
      };
      home.file.".config/sketchybar/icons.sh".source = source + "/icons.sh";
      home.file.".config/sketchybar/items".source = source + "/items";
      home.file.".config/sketchybar/plugins".source = source + "/plugins";
    };

  flake.modules.darwin.sketchybar =
    { pkgs, ... }:
    {
      services.sketchybar = {
        enable = true;
        package = pkgs.sketchybar;
      };

      fonts.packages = [ pkgs.sketchybar-app-font ];

    };
}
