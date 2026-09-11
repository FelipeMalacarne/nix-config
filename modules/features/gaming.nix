{ inputs, lib, ... }:
let
  homeGaming =
    { config, pkgs, ... }:
    {
      options.my.gaming.enable = lib.mkEnableOption "gaming";
      config = lib.mkIf config.my.gaming.enable {
        home.packages = with pkgs; [
          lutris
          heroic
          mangohud
          gamescope
          dxvk
          cemu
          prismlauncher
          ferium
          bolt-launcher
          xivlauncher
          hydralauncher
          inputs.jagex-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
    };
in
{
  flake.homeModules.gaming = homeGaming;

  flake.nixosModules.gaming =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.my.gaming.enable = lib.mkEnableOption "gaming";
      config = lib.mkIf config.my.gaming.enable {
        home-manager.users.${config.my.user.name} = {
          imports = [ homeGaming ];
          my.gaming.enable = true;
        };
        nixpkgs.overlays = [ inputs.millennium.overlays.default ];

        hardware.graphics.enable = true;

        # stardew valley port
        networking.firewall.allowedUDPPorts = [ 24642 ];
        networking.firewall.allowedTCPPorts = [ 24642 ];

        programs = {
          gamemode.enable = true;
          gamescope.enable = true;

          steam = {
            enable = true;
            package = pkgs.millennium-steam;
            protontricks.enable = true;
            extraCompatPackages = [ pkgs.proton-ge-bin ];
          };
        };

      };
    };
}
