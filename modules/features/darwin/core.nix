{ inputs, ... }:
{
  flake.darwinModules.core =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      nix.settings = {
        experimental-features = "nix-command flakes";
        substituters = [ "https://nvf.cachix.org" ];
        trusted-public-keys = [ "nvf.cachix.org-1:GMQWiUhZ6ux9D5CvFFMwnc2nFrUHTeGaXRlVBXo+naI=" ];
      };
      nixpkgs.config.allowUnfree = true;

      system.primaryUser = user;
      system.defaults.NSGlobalDomain._HIHideMenuBar = true;

      users.users.${user} = {
        name = user;
        home = "/Users/${user}";
      };

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";

      home-manager.users.${user}.home = {
        username = user;
        homeDirectory = lib.mkDefault "/Users/${user}";
        stateVersion = lib.mkDefault "24.11";
      };
    };
}
