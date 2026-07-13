{
  flake.homeModules.alacritty =
    { lib, ... }:
    {
      home.sessionVariables.TERMINAL = "alacritty";

      programs.alacritty = {
        enable = true;
        settings = {
          env.TERM = "xterm-256color";

          window = {
            decorations = "None";
            opacity = lib.mkForce 0.95;
          };

          keyboard.bindings = [
            {
              key = "Return";
              mods = "Shift";
              chars = "\\u001B\\r";
            }
            {
              key = "Left";
              mods = "Control";
              chars = "\\u001Bb";
            }
            {
              key = "Right";
              mods = "Control";
              chars = "\\u001Bf";
            }
            {
              key = "Left";
              mods = "Alt";
              chars = "\\u0001";
            }
            {
              key = "Right";
              mods = "Alt";
              chars = "\\u0005";
            }
          ];
        };
      };
    };
}
