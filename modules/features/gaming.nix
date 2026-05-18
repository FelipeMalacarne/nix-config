# modules/features/gaming.nix
#
# Gaming stack: Steam, Proton GE, Gamemode.
{
  pkgs,
  config,
  ...
}:
let
  user = config.myConfig.primaryUser;
in
{
  nixpkgs.overlays = [
    (_final: prev: {
      pkgsi686Linux = prev.pkgsi686Linux.extend (_final32: prev32: {
        openldap = prev32.openldap.overrideAttrs (_old: {
          # Lutris' 32-bit closure currently hits flaky OpenLDAP replication tests.
          doCheck = false;
        });
      });
    })
  ];

  hardware.graphics.enable = true;

  programs = {
    gamemode.enable = true;
    gamescope.enable = true;

    steam = {
      enable = true;
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
      prismlauncher
      ferium
      bolt-launcher
    ];
  };
}
