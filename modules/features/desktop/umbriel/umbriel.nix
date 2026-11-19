{ inputs, config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.umbriel =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.umbriel.nixosModules.default ];

      config = {
        my.desktop.sessions = [ "umbriel" ];
        home-manager.sharedModules = [ registry.homeManager.umbriel ];
        programs.umbriel = {
          enable = true;
          portalPackage =
            inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-umbriel;
        };
        services.displayManager.defaultSession = lib.mkIf (
          config.my.desktop.defaultSession == "umbriel"
        ) "umbriel";
        home-manager.users.${config.my.user.name}.programs.umbriel.package =
          config.programs.umbriel.package;
      };
    };

  flake.modules.homeManager.umbriel = {
    imports = [
      inputs.umbriel.homeModules.default
      ./config/home.nix
    ];
  };
}
