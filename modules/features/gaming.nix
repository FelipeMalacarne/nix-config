{ pkgs, inputs, config, ... }:
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

  home-manager.users.${config.myConfig.primaryUser} = {
    home = {
      packages = with pkgs; [
        lutris
        heroic
        mangohud
        gamescope
        dxvk
      ];
    };
  };
}
