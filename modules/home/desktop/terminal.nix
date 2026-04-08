# modules/home/desktop/terminal.nix
#
# Single place to switch between terminal emulators.
# Set `desktop.terminal.name` in the host file to "ghostty" or "alacritty".
# All Hyprland references (TERMINAL env, keybind) read from this option.
{ lib, pkgs, config, ... }:
let
  p    = config.colorScheme.palette;
  term = config.desktop.terminal.name;
in
{
  options.desktop.terminal = {
    name = lib.mkOption {
      type        = lib.types.enum [ "ghostty" "alacritty" ];
      default     = "ghostty";
      description = "Which terminal emulator to use system-wide.";
    };
    exec = lib.mkOption {
      type     = lib.types.str;
      readOnly = true;
      default  = "uwsm app -- ${config.desktop.terminal.name}";
    };
    openCmd = lib.mkOption {
      type     = lib.types.str;
      readOnly = true;
      default  = {
        ghostty   = "open -na Ghostty";
        alacritty = "open -na Alacritty";
      }.${term};
    };
  };

  config = lib.mkMerge [

    # Shared: font, session TERMINAL var, and yazi desktop entry
    {
      home.packages = [ pkgs.nerd-fonts.fira-code ];

      # Export TERMINAL to the full systemd user session, not just Hyprland's env.
      # Launchers (e.g. noctalia) use this to open TUI apps like yazi.
      home.sessionVariables.TERMINAL = term;

    }

    # ── Ghostty ────────────────────────────────────────────────────────────
    (lib.mkIf (term == "ghostty") (
      let
        ghosttySettings = {
          font-family           = "FiraCode Nerd Font Mono";
          font-size             = 16;
          background-opacity    = 0.95;
          window-decoration     = false;
          confirm-close-surface = false;

          background           = p.base00;
          foreground           = p.base05;
          cursor-color         = p.base06;
          selection-background = p.base06;
          selection-foreground = p.base00;

          palette = [
            "0=#${p.base00}"   # black
            "1=#${p.base08}"   # red
            "2=#${p.base0B}"   # green
            "3=#${p.base0A}"   # yellow
            "4=#${p.base0D}"   # blue
            "5=#${p.base0E}"   # magenta
            "6=#${p.base0C}"   # cyan
            "7=#${p.base05}"   # white
            "8=#${p.base03}"   # bright black
            "9=#${p.base08}"   # bright red
            "10=#${p.base0B}"  # bright green
            "11=#${p.base0A}"  # bright yellow
            "12=#${p.base0D}"  # bright blue
            "13=#${p.base0E}"  # bright magenta
            "14=#${p.base0C}"  # bright cyan
            "15=#${p.base07}"  # bright white
          ];
          keybind = [
            "shift+enter=text:\\x1b\\r"
            "ctrl+left=text:\\x1bb"
            "ctrl+right=text:\\x1bf"
            "alt+left=text:\\x01"
            "alt+right=text:\\x05"
          ];
        };
      in
      {
        # On Linux: install package + write config via home-manager module
        programs.ghostty = lib.mkIf pkgs.stdenv.isLinux {
          enable   = true;
          settings = ghosttySettings;
        };

        # On macOS: ghostty is installed externally (Homebrew); just write the config
        xdg.configFile."ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
          text = lib.generators.toKeyValue {
            listsAsDuplicateKeys = true;
          } ghosttySettings;
        };
      }
    ))

    # ── Alacritty ──────────────────────────────────────────────────────────
    (lib.mkIf (term == "alacritty") {
      programs.alacritty = {
        enable = true;
        settings = {
          env.TERM = "xterm-256color";

          window = {
            decorations = "None";
            opacity      = 0.95;
          };

          font = {
            normal = {
              family = "FiraCode Nerd Font Mono";
              style  = "Regular";
            };
            size = 16.0;
          };

          colors = {
            primary = {
              background = "#${p.base00}";
              foreground = "#${p.base05}";
            };
            cursor = {
              text   = "#${p.base00}";
              cursor = "#${p.base06}";
            };
            selection = {
              text       = "#${p.base00}";
              background = "#${p.base06}";
            };
            normal = {
              black   = "#${p.base00}";
              red     = "#${p.base08}";
              green   = "#${p.base0B}";
              yellow  = "#${p.base0A}";
              blue    = "#${p.base0D}";
              magenta = "#${p.base0E}";
              cyan    = "#${p.base0C}";
              white   = "#${p.base05}";
            };
            bright = {
              black   = "#${p.base03}";
              red     = "#${p.base08}";
              green   = "#${p.base0B}";
              yellow  = "#${p.base0A}";
              blue    = "#${p.base0D}";
              magenta = "#${p.base0E}";
              cyan    = "#${p.base0C}";
              white   = "#${p.base07}";
            };
          };

          keyboard.bindings = [
            { key = "Return"; mods = "Shift";   chars = "\\u001B\\r"; }
            { key = "Left";   mods = "Control"; chars = "\\u001Bb"; }
            { key = "Right";  mods = "Control"; chars = "\\u001Bf"; }
            { key = "Left";   mods = "Alt";     chars = "\\u0001"; }
            { key = "Right";  mods = "Alt";     chars = "\\u0005"; }
          ];
        };
      };
    })

  ];
}
