{
  flake.darwinModules.skhd =
    let
      termCmd = "open -na Alacritty";
    in
    {
      services.skhd.enable = true;
      services.skhd.skhdConfig = ''
        alt - w : skhd -k "cmd - w"
        alt + shift - w : skhd -k "cmd - q"
        alt - h : yabai -m window --focus west
        alt - j : yabai -m window --focus south
        alt - k : yabai -m window --focus north
        alt - l : yabai -m window --focus east
        alt + shift - h : yabai -m window --swap west
        alt + shift - j : yabai -m window --swap south
        alt + shift - k : yabai -m window --swap north
        alt + shift - l : yabai -m window --swap east
        cmd + shift - h : yabai -m window --warp west
        cmd + shift - j : yabai -m window --warp south
        cmd + shift - k : yabai -m window --warp north
        cmd + shift - l : yabai -m window --warp east
        alt + shift - r : yabai -m space --rotate 270
        alt + shift - x : yabai -m space --mirror x-axis
        alt + shift - y : yabai -m space --mirror y-axis
        alt + shift - a : yabai -m window --resize left:-48:0
        alt + shift - d : yabai -m window --resize right:48:0
        alt + shift - w : yabai -m window --resize top:0:-48
        alt + shift - s : yabai -m window --resize bottom:0:48
        cmd + shift - a : yabai -m window --resize left:48:0
        cmd + shift - d : yabai -m window --resize right:-48:0
        cmd + shift - w : yabai -m window --resize top:0:48
        cmd + shift - s : yabai -m window --resize bottom:0:-48
        alt - d : yabai -m window --toggle zoom-parent
        alt - f : yabai -m window --toggle zoom-fullscreen
        shift + alt - 0 : yabai -m space --balance
        alt - t : yabai -m window --toggle float --grid 8:8:1:1:6:6
        ctrl + shift - a : yabai -m window --move rel:-12:0
        ctrl + shift - d : yabai -m window --move rel:12:0
        ctrl + shift - w : yabai -m window --move rel:0:-12
        ctrl + shift - s : yabai -m window --move rel:0:12
        ctrl + alt - up : yabai -m window --grid 1:1:0:0:1:1
        ctrl + alt - down : yabai -m window --grid 8:8:1:1:6:6
        ctrl + alt - left : yabai -m window --grid 1:2:0:0:1:1
        ctrl + alt - right : yabai -m window --grid 1:2:1:0:1:1
        alt - e : yabai -m window --toggle split
        ctrl + shift - z : yabai -m window --space next; yabai -m space --focus prev
        ctrl + shift - x : yabai -m window --space next; yabai -m space --focus next
        ctrl + shift - 1 : yabai -m window --space 1
        ctrl + shift - 2 : yabai -m window --space 2
        ctrl + shift - 3 : yabai -m window --space 3
        ctrl + shift - 4 : yabai -m window --space 4
        ctrl + shift - 5 : yabai -m window --space 5
        ctrl + shift - 6 : yabai -m window --space 6
        ctrl + shift - 7 : yabai -m window --space 7
        ctrl + shift - 8 : yabai -m window --space 8
        ctrl + shift - 9 : yabai -m window --space 9
        ctrl + shift - 0 : yabai -m window --space 10
        ctrl + alt - z : yabai -m display --focus prev
        ctrl + alt - x : yabai -m display --focus next
        ctrl + alt - 1 : yabai -m display --focus 1
        ctrl + alt - 2 : yabai -m display --focus 2
        ctrl + alt - 3 : yabai -m display --focus 3
        alt - return : ${termCmd}
        alt + shift - b : open -na Firefox
        alt + shift - f : ${termCmd} --args -e yazi
        alt + shift - t : ${termCmd} --args -e btop
        alt + shift - i : ${termCmd} --args -e fastfetch
        ctrl + alt + cmd - r : launchctl stop org.nixos.yabai && launchctl start org.nixos.yabai & launchctl stop org.nixos.skhd && launchctl start org.nixos.skhd
      '';
    };
}
