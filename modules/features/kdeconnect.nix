{
  flake.nixosModules.kdeconnect =
    {
      lib,
      options,
      pkgs,
      ...
    }:
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

      home-manager.sharedModules = lib.optional (options ? home-manager) {
        services.kdeconnect.enable = true;
        home.packages = [ pkgs.kdePackages.kdeconnect-kde ];
      };
    };
}
