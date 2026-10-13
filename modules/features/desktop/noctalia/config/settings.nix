{ config, lib, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
  baseline = builtins.fromTOML (builtins.readFile ./settings.toml);
in
{
  config =
    lib.mkIf
      (
        config.my.desktop.shell == "noctalia"
        && lib.any (session: builtins.elem session config.my.desktop.sessions) [
          "hyprland"
          "umbriel"
        ]
      )
      {
        programs.noctalia = {
          # v5 no longer provides v4's native Stylix target.
          customPalettes.stylix.dark = {
            mPrimary = colors.base0D;
            mOnPrimary = colors.base00;
            mSecondary = colors.base0E;
            mOnSecondary = colors.base00;
            mTertiary = colors.base0C;
            mOnTertiary = colors.base00;
            mError = colors.base08;
            mOnError = colors.base00;
            mSurface = colors.base00;
            mOnSurface = colors.base05;
            mSurfaceVariant = colors.base01;
            mOnSurfaceVariant = colors.base04;
            mOutline = colors.base03;
            mShadow = "#000000";
            mHover = colors.base02;
            mOnHover = colors.base05;
            # Required by the palette loader even without terminal templates.
            terminal = {
              background = colors.base00;
              foreground = colors.base05;
              cursor = colors.base05;
              cursorText = colors.base00;
              selectionBg = colors.base02;
              selectionFg = colors.base05;
              normal = {
                black = colors.base00;
                red = colors.base08;
                green = colors.base0B;
                yellow = colors.base0A;
                blue = colors.base0D;
                magenta = colors.base0E;
                cyan = colors.base0C;
                white = colors.base05;
              };
              bright = {
                black = colors.base03;
                red = colors.base08;
                green = colors.base0B;
                yellow = colors.base0A;
                blue = colors.base0D;
                magenta = colors.base0E;
                cyan = colors.base0C;
                white = colors.base07;
              };
            };
          };

          # GUI overrides still load last; this only defines the portable baseline.
          settings = lib.recursiveUpdate baseline {
            shell = {
              font_family = config.stylix.fonts.sansSerif.name;
              avatar_path = "${config.home.homeDirectory}/.face";
            };
            bar = lib.optionalAttrs (builtins.hasAttr "default" (baseline.bar or { })) {
              default = {
                background_opacity = config.stylix.opacity.desktop;
                capsule_opacity = config.stylix.opacity.desktop;
              };
            };
            widget =
              lib.genAttrs
                (lib.filter (name: builtins.hasAttr name (baseline.widget or { })) [
                  "cpu"
                  "cpu_temp"
                  "ram"
                  "temp"
                ])
                (_: {
                  font_family = config.stylix.fonts.monospace.name;
                });
            dock.background_opacity = config.stylix.opacity.desktop;
            notification.background_opacity = config.stylix.opacity.popups;
            osd.background_opacity = config.stylix.opacity.popups;
            wallpaper.default.path = toString config.stylix.image;
            # Hypridle remains responsible for idle timeouts.
            idle.behavior = {
              lock.enabled = false;
              screen-off.enabled = false;
              lock-and-suspend.enabled = false;
            };
          };
        };
      };
}
