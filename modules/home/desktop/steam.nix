# modules/home/desktop/steam.nix
#
# Generates a Millennium Steam theme from the active nix-colors colorScheme
# and sets it as the active theme via settings.json.
#
# Theme CSS variables map base16 → Catppuccin Mocha names for reference:
#   base00=base  base01=mantle  base02=surface0  base03=surface1
#   base04=surface2/overlay2  base05=text  base06=subtext0  base07=subtext1
#   base08=red   base09=peach  base0A=yellow  base0B=green
#   base0C=teal  base0D=blue   base0E=mauve   base0F=flamingo
{
  config,
  lib,
  pkgs,
  ...
}:
let
  p = config.colorScheme.palette;
  themeName = "nix-colors";

  skinJson = builtins.toJSON {
    name = themeName;
    version = "1.0.0";
    description = "Generated from nix-colors colorScheme — do not edit manually";
    GlobalsColors = {
      "--millennium-accent" = "#${p.base0E}";
      "--millennium-accent-hover" = "#${p.base0D}";
      "--millennium-bg" = "#${p.base00}";
      "--millennium-bg-2" = "#${p.base01}";
      "--millennium-surface" = "#${p.base02}";
      "--millennium-surface-2" = "#${p.base03}";
      "--millennium-text" = "#${p.base05}";
      "--millennium-text-muted" = "#${p.base04}";
      "--millennium-green" = "#${p.base0B}";
      "--millennium-red" = "#${p.base08}";
      "--millennium-yellow" = "#${p.base0A}";
    };
  };

  # webkit.css targets all Steam web views (store, community, etc.)
  webkitCss = ''
    :root {
      --gpColor-Highlight:                #${p.base0E};
      --gpColor-HighlightHover:           #${p.base0D};
      --gpColor-PositiveGreen:            #${p.base0B};
      --gpColor-ErrorRed:                 #${p.base08};
      --gpColor-WarningYellow:            #${p.base0A};

      /* Backgrounds */
      --gpColor-AppBackground:            #${p.base00};
      --gpColor-NavBackground:            #${p.base01};
      --gpColor-SectionBackground:        #${p.base02};
      --gpColor-SectionBackgroundHover:   #${p.base03};

      /* Text */
      --gpColor-Text-Primary:             #${p.base05};
      --gpColor-Text-Secondary:           #${p.base04};
      --gpColor-Text-Tertiary:            #${p.base03};

      /* Borders */
      --gpColor-Border:                   #${p.base02};
      --gpColor-BorderStrong:             #${p.base03};
    }
  '';

  # libraryroot.custom.css targets the main Steam library window
  libraryCss = ''
    :root {
      --store-header-background:          #${p.base01};
      --main-editor-bgcolor:              #${p.base00};
      --games-list-bg:                    #${p.base01};
      --selected-game-overlay:            #${p.base02};
    }
  '';
in
{
  home.file = {
    ".local/share/Steam/steamui/skins/${themeName}/skin.json".text = skinJson;
    ".local/share/Steam/steamui/skins/${themeName}/webkit.css".text = webkitCss;
    ".local/share/Steam/steamui/skins/${themeName}/libraryroot.custom.css".text = libraryCss;
  };

  # Write settings.json imperatively so Millennium can still mutate it at runtime
  # (e.g. to save other settings via its UI). On every rebuild we ensure
  # active-theme stays pointing at our generated theme.
  home.activation.millenniumActiveTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.local/share/Steam/ext/millennium/settings.json"
    $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
    if [ -f "$settings" ]; then
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        '."active-theme" = "${themeName}"' \
        "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    else
      $DRY_RUN_CMD printf '%s\n' '{"active-theme":"${themeName}"}' > "$settings"
    fi
  '';
}
