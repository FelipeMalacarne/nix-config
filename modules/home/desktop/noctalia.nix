# modules/home/desktop/noctalia.nix
#
# Maps the active colorScheme (base16) to Material 3 color tokens for Noctalia.
# base16 → Catppuccin Mocha reference:
#   base00=base  base02=surface0  base03=surface1  base04=surface2
#   base05=text  base06=rosewater base08=red        base0B=green
#   base0D=blue  base0E=mauve
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
      # === Surface / Background ===
      base               = "#${p.base00}";
      surface            = "#${p.base02}";
      "surface-variant"  = "#${p.base03}";

      # === Primary (mauve) ===
      primary                  = "#${p.base0E}";
      "on-primary"             = "#${p.base00}";
      "primary-container"      = "#${p.base03}";
      "on-primary-container"   = "#${p.base0E}";

      # === Secondary (blue) ===
      secondary                  = "#${p.base0D}";
      "on-secondary"             = "#${p.base00}";
      "secondary-container"      = "#${p.base02}";
      "on-secondary-container"   = "#${p.base0D}";

      # === Tertiary (green) ===
      tertiary                  = "#${p.base0B}";
      "on-tertiary"             = "#${p.base00}";
      "tertiary-container"      = "#${p.base02}";
      "on-tertiary-container"   = "#${p.base0B}";

      # === Error (red) ===
      error                  = "#${p.base08}";
      "on-error"             = "#${p.base00}";
      "error-container"      = "#${p.base03}";
      "on-error-container"   = "#${p.base08}";

      # === Text ===
      "on-surface"         = "#${p.base05}";
      "on-surface-variant" = "#${p.base04}";

      # === Outline ===
      outline         = "#${p.base04}";
      "outline-variant" = "#${p.base03}";

      # === Background ===
      background      = "#${p.base00}";
      "on-background" = "#${p.base05}";

      # === Inverse (snackbars, tooltips) ===
      "inverse-surface"    = "#${p.base05}";
      "inverse-on-surface" = "#${p.base00}";
      "inverse-primary"    = "#6c3483"; # darker mauve — not in base16
    };
  };
}
