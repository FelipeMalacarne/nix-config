{ inputs, ... }:
{
  flake.nixosModules.noctalia =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.my.user.name;
    in
    {
      networking.networkmanager.enable = true;
      hardware.bluetooth.enable = true;
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      home-manager.users.${user} = {
        imports = [ inputs.noctalia.homeModules.default ];

        home.packages = with pkgs; [
          grim
          imagemagick
          swappy
          tesseract
          xdg-utils
          jq
          wf-recorder
        ];

        stylix.targets.hyprpaper.enable = lib.mkForce false;
        services.hyprpaper.enable = lib.mkForce false;

        programs.noctalia = {
          enable = true;
          settings = { };
        };
      };
    };
}
