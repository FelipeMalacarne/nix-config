{ ... }:
{
  flake.nixosModules.hyprland = { config, pkgs, ... }: {
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

  flake.homeModules.hyprland =
    { pkgs, lib, ... }:
    let
      noctalia = lib.getExe pkgs.noctalia-shell;
      brightnessctl = lib.getExe pkgs.brightnessctl;
      grimblast = lib.getExe pkgs.grimblast;
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
      playerctl = lib.getExe pkgs.playerctl;
      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      yazi = lib.getExe pkgs.yazi;
      btop = lib.getExe pkgs.btop;
      bash = lib.getExe pkgs.bash;
      fastfetch = lib.getExe pkgs.fastfetch;
      firefox = lib.getExe pkgs.firefox;
      termHere = pkgs.writeShellScript "term-here" ''
        pid=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.pid // empty')
        cwd=""
        if [ -n "$pid" ]; then
          while child=$(pgrep -P "$pid" 2>/dev/null | head -1) && [ -n "$child" ]; do
            pid=$child
          done
          cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)
        fi
        if [ -n "$cwd" ] && [ -d "$cwd" ]; then
          exec uwsm app -- $TERMINAL --working-directory="$cwd"
        else
          exec uwsm app -- $TERMINAL
        fi
      '';
      luaConfig =
        builtins.replaceStrings
          [
            "@NOCTALIA@"
            "@BRIGHTNESSCTL@"
            "@GRIMBLAST@"
            "@HYPRCTL@"
            "@PLAYERCTL@"
            "@WPCTL@"
            "@YAZI@"
            "@BTOP@"
            "@BASH@"
            "@FASTFETCH@"
            "@FIREFOX@"
            "@TERM_HERE@"
          ]
          [
            noctalia
            brightnessctl
            grimblast
            hyprctl
            playerctl
            wpctl
            yazi
            btop
            bash
            fastfetch
            firefox
            "${termHere}"
          ]
          (builtins.readFile ./config/hyprland.lua);
    in
    {
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        extraLuaFiles.main = {
          content = luaConfig;
          autoLoad = true;
        };
      };

      home.file = {
        ".XCompose".text = ''
          include "%L"
          <dead_acute> <c> : "ç" ccedilla
          <dead_acute> <C> : "Ç" Ccedilla
        '';
      };
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      home.pointerCursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 16;
        gtk.enable = true;
        x11.enable = true;
      };
      systemd.user.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "22";
        XCOMPOSEFILE = "$HOME/.XCompose";
      };
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "${noctalia} ipc call lockScreen lock";
            before_sleep_cmd = "${noctalia} ipc call lockScreen lock";
            after_sleep_cmd = "${hyprctl} dispatch dpms on";
          };
          listener = [
            {
              timeout = 180;
              on-timeout = "${noctalia} ipc call lockScreen lock";
            }
            {
              timeout = 240;
              on-timeout = "${hyprctl} dispatch dpms off";
              on-resume = "${hyprctl} dispatch dpms on";
            }
          ];
        };
      };
    };
}
