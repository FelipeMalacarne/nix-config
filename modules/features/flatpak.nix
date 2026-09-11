{
  flake.nixosModules.flatpak =
    { config, lib, ... }:
    {
      options.my.flatpak.enable = lib.mkEnableOption "Flatpak";
      config = lib.mkIf config.my.flatpak.enable {
        services.flatpak.enable = true;
      };
    };
}
