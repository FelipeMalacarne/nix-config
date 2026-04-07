# modules/home/desktop/noctalia.nix
#
# Maps the active colorScheme (base16) to Noctalia color keys (m-prefixed camelCase).
# base16 → Catppuccin Mocha reference:
#   base00=base  base02=surface0  base03=surface1  base04=surface2
#   base05=text  base08=red       base0B=green     base0D=blue  base0E=mauve
#
# To switch themes: set `colorScheme` in the host file.
{ inputs, config, ... }:
let
  p = config.colorScheme.palette;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;

    colors = {
      mSurface = "#${p.base01}";
      mSurfaceVariant = "#${p.base02}";
      mPrimary = "#${p.base0E}";
      mOnPrimary = "#${p.base00}";
      mSecondary = "#${p.base0D}";
      mOnSecondary = "#${p.base00}";
      mTertiary = "#${p.base0B}";
      mOnTertiary = "#${p.base00}";
      mError = "#${p.base08}";
      mOnError = "#${p.base00}";
      mOnSurface = "#${p.base05}";
      mOnSurfaceVariant = "#${p.base04}";
      mOutline = "#${p.base03}";
      mHover = "#${p.base02}";
      mOnHover = "#${p.base05}";
      mShadow = "#000000";

    };

    settings = {
      wallpaper = {
        enable = false;
      };
    };
  };
}
