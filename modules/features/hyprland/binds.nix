{ pkgs, ... }:
let
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
in
{
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    "$ipc" = "noctalia-shell ipc call";

    bind = [
      "$mod, Return, exec, ${termHere}"
      "$mod, W, killactive"
      "$mod, F, fullscreen"
      "$mod, T, togglefloating"
      "$mod, E, layoutmsg, togglesplit"
      "$mod, Space, exec, $ipc launcher toggle"
      "$mod, C, exec, $ipc controlCenter toggle"
      "$mod, comma, exec, $ipc settings toggle"
      "$mod SHIFT, Escape, exec, $ipc sessionMenu toggle"
      "$mod Control, L, exec, $ipc lockScreen lock"

      # Focus
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"

      # Move windows
      "$mod SHIFT, H, movewindow, l"
      "$mod SHIFT, L, movewindow, r"
      "$mod SHIFT, K, movewindow, u"
      "$mod SHIFT, J, movewindow, d"

      # Workspaces
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"

      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"

      # apps
      "$mod SHIFT, F, exec, uwsm app -- $TERMINAL -e yazi"
      "$mod SHIFT, T, exec, uwsm app -- $TERMINAL -e btop"
      "$mod SHIFT, I, exec, uwsm app -- $TERMINAL -e bash -c 'fastfetch; read -rp \"Press enter to close...\"'"
      "$mod SHIFT, B, exec, uwsm app -- firefox"
    ];

    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];

    bindel = [
      ", XF86AudioRaiseVolume, exec, $ipc volume increase"
      ", XF86AudioLowerVolume, exec, $ipc volume decrease"
    ];

    bindl = [
      ", XF86AudioMute, exec, $ipc volume muteOutput"
    ];

  };
}
