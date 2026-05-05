# modules/features/gaming.nix
#
# Gaming stack: Steam with Millennium, Proton GE, Gamemode.
{
  pkgs,
  inputs,
  config,
  ...
}:
let
  user = config.myConfig.primaryUser;
in
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

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      lutris
      heroic
      mangohud
      gamescope
      dxvk
      cemu
    ];
  };
}
