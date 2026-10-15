{ inputs, self }:
let
  # Explicit synthetic modules only: importing base must not require SOPS.
  mkFeatureConfig =
    modules:
    (inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit self inputs; };
      modules = modules ++ [
        {
          system.stateVersion = "24.11";
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
        }
      ];
    }).config;
in
{
  inherit mkFeatureConfig;
  homeOf = host: host.home-manager.users.${host.my.user.name};
  baseOnly = mkFeatureConfig [ self.modules.nixos.base ];
  serverOnly = mkFeatureConfig [ self.modules.nixos.server ];
  desktopWithoutHermes = mkFeatureConfig [
    self.modules.nixos.base
    self.modules.nixos.desktop
    self.modules.nixos.development
    {
      my.desktop = {
        sessions = [
          "umbriel"
          "hyprland"
          "i3"
        ];
        defaultSession = "hyprland";
      };
    }
  ];
}
