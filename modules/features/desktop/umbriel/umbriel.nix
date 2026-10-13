{ inputs, ... }:
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

      config = lib.mkIf (builtins.elem "umbriel" config.my.desktop.sessions) {
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
