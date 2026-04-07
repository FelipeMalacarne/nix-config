# modules/home/desktop/hyprland/binds.nix
{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bind = [
      "$mod, Return, exec, uwsm app -- alacritty" # UWSM wraps apps when withUWSM = true
      "$mod, Q, killactive"
      "$mod, M, exit"
      "$mod, F, fullscreen"
      "$mod, V, togglefloating"

      # App launcher — requires a launcher installed (e.g. rofi, fuzzel, or Noctalia's built-in)
      # Noctalia may provide its own launcher — check its docs and update this bind accordingly
      "$mod, Space, exec, uwsm app -- fuzzel"

      # Focus movement
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"

      # Workspace switching
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"

      # Move window to workspace
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
    ];

    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };
}
