{
  flake.modules.darwin.skhd =
    let
      termCmd = "open -na Ghostty";
      mod = "alt";
    in
    {
      services.skhd.enable = true;
      services.skhd.skhdConfig = ''
        ${mod} - w : skhd -k "cmd - w"
        ${mod} + shift - w : skhd -k "cmd - q"
        ${mod} - h : yabai -m window --focus west
        ${mod} - j : yabai -m window --focus south
        ${mod} - k : yabai -m window --focus north
        ${mod} - l : yabai -m window --focus east

        ${mod} + shift - h : yabai -m window --swap west
        ${mod} + shift - j : yabai -m window --swap south
        ${mod} + shift - k : yabai -m window --swap north
        ${mod} + shift - l : yabai -m window --swap east
        ${mod} + ctrl - h : yabai -m window --warp west
        ${mod} + ctrl - j : yabai -m window --warp south
        ${mod} + ctrl - k : yabai -m window --warp north
        ${mod} + ctrl - l : yabai -m window --warp east

        ${mod} + shift - r : yabai -m space --rotate 270
        ${mod} + shift - x : yabai -m space --mirror x-axis
        ${mod} + shift - y : yabai -m space --mirror y-axis
        ${mod} + shift - a : yabai -m window --resize left:-48:0
        ${mod} + shift - d : yabai -m window --resize right:48:0
        ${mod} + shift - w : yabai -m window --resize top:0:-48
        ${mod} + shift - s : yabai -m window --resize bottom:0:48

        cmd + shift - a : yabai -m window --resize left:48:0
        cmd + shift - d : yabai -m window --resize right:-48:0
        cmd + shift - w : yabai -m window --resize top:0:48
        cmd + shift - s : yabai -m window --resize bottom:0:-48

        ${mod} - d : yabai -m window --toggle zoom-parent
        ${mod} - f : yabai -m window --toggle zoom-fullscreen

        shift + ${mod} - 0 : yabai -m space --balance
        ${mod} - t : yabai -m window --toggle float --grid 8:8:1:1:6:6
        ctrl + shift - a : yabai -m window --move rel:-12:0
        ctrl + shift - d : yabai -m window --move rel:12:0
        ctrl + shift - w : yabai -m window --move rel:0:-12
        ctrl + shift - s : yabai -m window --move rel:0:12
        ctrl + ${mod} - up : yabai -m window --grid 1:1:0:0:1:1
        ctrl + ${mod} - down : yabai -m window --grid 8:8:1:1:6:6
        ctrl + ${mod} - left : yabai -m window --grid 1:2:0:0:1:1
        ctrl + ${mod} - right : yabai -m window --grid 1:2:1:0:1:1
        ${mod} - e : yabai -m window --toggle split

        # spaces
        ${mod} - 1 : yabai -m space --focus 1
        ${mod} - 2 : yabai -m space --focus 2
        ${mod} - 3 : yabai -m space --focus 3
        ${mod} - 4 : yabai -m space --focus 4
        ${mod} - 4 : yabai -m space --focus 4
        ${mod} - 5 : yabai -m space --focus 5
        ${mod} - 6 : yabai -m space --focus 6
        ${mod} - 7 : yabai -m space --focus 7

        ${mod} + shift - z : yabai -m window --space next; yabai -m space --focus prev
        ${mod} + shift - x : yabai -m window --space next; yabai -m space --focus next

        ${mod} + shift - 1 : yabai -m window --space 1; yabai -m space --focus 1
        ${mod} + shift - 2 : yabai -m window --space 2; yabai -m space --focus 2
        ${mod} + shift - 3 : yabai -m window --space 3; yabai -m space --focus 3
        ${mod} + shift - 4 : yabai -m window --space 4; yabai -m space --focus 4
        ${mod} + shift - 5 : yabai -m window --space 5; yabai -m space --focus 5
        ${mod} + shift - 6 : yabai -m window --space 6; yabai -m space --focus 6
        ${mod} + shift - 7 : yabai -m window --space 7; yabai -m space --focus 7

        ctrl + ${mod} - z : yabai -m display --focus prev
        ctrl + ${mod} - x : yabai -m display --focus next
        ctrl + ${mod} - 1 : yabai -m display --focus 1
        ctrl + ${mod} - 2 : yabai -m display --focus 2
        ctrl + ${mod} - 3 : yabai -m display --focus 3

        ${mod} - return : ${termCmd}
        ${mod} + shift - b : open -na Firefox
        ${mod} + shift - f : ${termCmd} --args -e yazi
        ${mod} + shift - t : ${termCmd} --args -e btop
        ${mod} + shift - i : ${termCmd} --args -e fastfetch

        ctrl + ${mod} + cmd - r : launchctl stop org.nixos.yabai && launchctl start org.nixos.yabai & launchctl stop org.nixos.skhd && launchctl start org.nixos.skhd
      '';
    };
}
