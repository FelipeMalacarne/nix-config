{
  flake.darwinModules.core = { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      nix.settings.experimental-features = "nix-command flakes";
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
