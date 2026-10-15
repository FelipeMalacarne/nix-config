{ ... }:
{
  my.desktop = {
    shell = "noctalia";
    defaultSession = "hyprland";

    sessions = [
      "umbriel"
      "hyprland"
      "i3"
    ];

    monitors = {
      main = {
        role = "primary";
        match = {
          # Live Wayland probe: DP-4; XRandR's original connector stays separate.
          waylandDescription = "Samsung Electric Company Odyssey G61SD HNBYB00003";
          xrandrOutput = "DP-1";
        };
        mode = {
          width = 2560;
          height = 1440;
          refresh = 239.76;
        };
        position = {
          x = 0;
          y = 0;
        };
        workspaces = [
          "1"
          "2"
          "3"
          "4"
          "5"
        ];
      };
      secondary = {
        role = "secondary";
        match = {
          # Confirmed historical identity; this portrait output is currently disconnected.
          waylandDescription = "Samsung Electric Company LS27A600U HNMW900149";
          xrandrOutput = "HDMI-A-1";
        };
        mode = {
          width = 2560;
          height = 1440;
          refresh = 74.97;
        };
        position = {
          x = 2560;
          y = 0;
        };
        rotation = 90;
        workspaces = [
          "6"
          "7"
          "8"
          "9"
        ];
      };
    };
  };
}
