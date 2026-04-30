# modules/features/kdeconnect.nix
{ lib, options, ... }:
{
  programs.kdeconnect.enable = true;

  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  home-manager.sharedModules = lib.optional (options ? home-manager) (
    { pkgs, ... }:
    {
      services.kdeconnect.enable = true;
      home.packages = [ pkgs.kdePackages.kdeconnect-kde ];
    }
  );
}
