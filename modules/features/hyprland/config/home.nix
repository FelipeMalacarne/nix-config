{ config, ... }:
{
  flake.homeModules.hyprland =
    let
      idle = config.flake.homeModules.hyprlandIdle;
    in
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
          (builtins.readFile ./hyprland.lua);
      rotationTransform =
        rotation:
        if rotation == 90 then
          ", transform = 1"
        else if rotation == 180 then
          ", transform = 2"
        else if rotation == 270 then
          ", transform = 3"
        else
          "";
      topologyLua = lib.concatMapStringsSep "\n" (
        output:
        let
          waylandOutput = "desc:${output.match.waylandDescription}";
          mode = "${toString output.mode.width}x${toString output.mode.height}@${toString output.mode.refresh}";
          position = "${toString output.position.x}x${toString output.position.y}";
        in
        ''
          hl.monitor({ output = ${builtins.toJSON waylandOutput}, mode = ${builtins.toJSON mode}, position = ${builtins.toJSON position}, scale = ${toString output.scale}${rotationTransform output.rotation} })
          ${lib.concatMapStringsSep "\n" (
            workspace:
            "hl.workspace_rule({ workspace = ${builtins.toJSON workspace}, monitor = ${builtins.toJSON waylandOutput} })"
          ) output.workspaces}
        ''
      ) (lib.attrValues config.my.desktop.monitors);
    in
    {
      imports = [ idle ];
      config = lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions) {
        wayland.windowManager.hyprland = {
          enable = true;
          configType = "lua";
          extraLuaFiles.main = {
            content = topologyLua + "\n" + luaConfig;
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
      };
    };
}
