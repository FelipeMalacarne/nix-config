{ config, inputs, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.darwin.core =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        registry.darwin.home-manager-policy
      ];

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
        home =
          if config.my.user.homeDirectory == null then "/Users/${user}" else config.my.user.homeDirectory;
      };

      home-manager.users.${user} = {
        imports = [ registry.homeManager.identity ];
        my.user = config.my.user;
        home = {
          username = user;
          homeDirectory = lib.mkDefault (
            if config.my.user.homeDirectory == null then "/Users/${user}" else config.my.user.homeDirectory
          );
          stateVersion = lib.mkDefault "24.11";
        };
      };
    };
}
