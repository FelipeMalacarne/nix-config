{ inputs, ... }:
{
  flake.homeModules.gaming = { pkgs, ... }: {
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
    ];
  };

  flake.nixosModules.gaming =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [ inputs.millennium.overlays.default ];

      hardware.graphics.enable = true;

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
}
