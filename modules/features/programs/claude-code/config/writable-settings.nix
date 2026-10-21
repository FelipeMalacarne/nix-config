{ config, inputs, ... }:
{
  flake.modules.homeManager.claude-code =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.claude-code;
      settings = "${cfg.configDir}/settings.json";
      baseline = "${cfg.configDir}/settings.nix.json";
      # Reuse upstream's complete rendering, including marketplaces and disabled
      # MCP servers, rather than maintaining a second settings serializer.
      source = config.home.file.${settings}.source;
      merge = lib.escapeShellArgs [
        "${pkgs.python3}/bin/python3"
        "-B"
        "${./settings.py}"
        (toString source)
        settings
        baseline
        builtins.storeDir
      ];
    in
    {
      home.file.${settings}.target = baseline;
      # Read the previous generation's baseline before linkGeneration replaces
      # it. Migration replaces only the old Home Manager settings symlink.
      home.activation.claudeSettingsCheck = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        ${merge} --check
      '';
      home.activation.claudeSettings = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        run ${merge}
      '';
    };

  perSystem = { lib, pkgs, ... }: {
    checks.claude-settings = import ./test-settings.nix {
      inherit lib pkgs;
      inherit (inputs) home-manager;
      module = config.flake.modules.homeManager.claude-code;
    };
  };
}
