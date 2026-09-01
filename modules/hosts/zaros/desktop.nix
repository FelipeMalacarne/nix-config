{ ... }:
{
  flake.nixosModules.zarosDesktopPolicy =
    { ... }:
    {
      my.desktop = {

        sessions = [
          "hyprland"
          "i3"
        ];

        monitors = {
          main = {
            role = "primary";
            match = {
              waylandDescription = "Samsung Electric Company Odyssey G61SD";
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
              waylandDescription = "Samsung Electric Company LS27A600U";
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
    };
}
