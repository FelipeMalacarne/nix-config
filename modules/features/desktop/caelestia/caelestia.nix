{ inputs, ... }:
{
  flake.modules.homeManager.caelestia =
    { config, lib, ... }:
    let
      caelestia = lib.getExe config.programs.caelestia.cli.package;
    in
    {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      config = lib.mkMerge [
        {
          my.desktop.shellProviders.caelestia.commands = {
            launcher = "${caelestia} shell drawers toggle launcher";
            dashboard = "${caelestia} shell drawers toggle dashboard";
            settings = "${caelestia} shell nexus open";
            session = "${caelestia} shell drawers toggle session";
            lock = "${caelestia} shell lock lock";
          };
        }
        (lib.mkIf
          (config.my.desktop.shell == "caelestia" && builtins.elem "hyprland" config.my.desktop.sessions)
          {
            programs.caelestia = {
              enable = true;
              systemd.enable = true;
              cli.enable = true;
            };
          }
        )
      ];
    };
}
