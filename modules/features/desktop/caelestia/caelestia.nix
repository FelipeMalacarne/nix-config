{ inputs, config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.caelestia = {
    my.desktop.shell = "caelestia";
    home-manager.sharedModules = [ registry.homeManager.caelestia ];
  };

  flake.modules.homeManager.caelestia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      # Upstream passes SETUPTOOLS_SCM_PRETEND_VERSION as an integer attribute,
      # which structured attributes never export, so hatch-vcs finds no git
      # metadata in the sandbox. Export it from the build phase instead.
      cli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default.overrideAttrs (old: {
        preBuild = ''
          ${old.preBuild or ""}
          export SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0
        '';
      });
      shell = inputs.caelestia-shell.packages.${system}.caelestia-shell.override {
        withCli = true;
        caelestia-cli = cli;
      };
      caelestia = lib.getExe config.programs.caelestia.cli.package;
    in
    {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      config = {
        programs.caelestia = {
          enable = true;
          package = shell;
          systemd.enable = true;
          systemd.target = "wayland-session@hyprland.desktop.target";
          cli.enable = true;
          cli.package = cli;
        };
        my.desktop.shellProviders.caelestia = {
          supportedSessions = [ "hyprland" ];
          startupCommand = null;
          commands = {
            launcher = "${caelestia} shell drawers toggle launcher";
            dashboard = "${caelestia} shell drawers toggle dashboard";
            settings = "${caelestia} shell nexus open";
            session = "${caelestia} shell drawers toggle session";
            lock = "${caelestia} shell lock lock";
          };
        };
      };
    };
}
