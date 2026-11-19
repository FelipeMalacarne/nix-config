{
  config,
  self,
  inputs,
  ...
}:
let
  registry = config.flake.modules;
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      craft = import ./config/craft-integration.nix {
        inherit lib;
        artcraft = config.programs.artcraft or null;
      };
    in
    {
      imports = with registry.homeManager; [
        ai-skills
        github-mcp
        linear-mcp
        playwright-mcp
      ];
      programs.mcp.enable = true;

      home.sessionVariables.OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";

      programs.opencode = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

        enableMcpIntegration = true;

        settings = {
          share = "manual";
          autoupdate = false;
          snapshot = true;

          permission = {
            external_directory = {
              "~/repos/**" = "allow";
              "~/orca/workspaces/**" = "allow";
            };
          };

          compaction = {
            auto = true;
            keep.tokens = 15000;
          };

          # Operational input budget, not advertised capacity. V2 reserves 10%,
          # so these GPT-6 models compact at about 245k tokens. A global buffer
          # sized for their 1M windows would break smaller models.
          providers.openai.models =
            lib.genAttrs
              [
                "gpt-6-astra"
                "gpt-6-astra-fast"
                "gpt-6-luna"
                "gpt-6-luna-fast"
                "gpt-6-sol"
                "gpt-6-sol-fast"
                "gpt-6.1-sol"
                "gpt-6.1-sol-fast"
              ]
              (_: {
                limit.input = 272000;
              });

          lsp = true;
        }
        // craft.settings;

        skills = craft.skills;
      };
    };
in
{
  flake.modules.homeManager.opencode = module;

  perSystem =
    {
      lib,
      pkgs,
      evalHome,
      ...
    }:
    let
      upstream = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system};
      restoreScripts = old: {
        postPatch = (old.postPatch or "") + ''
          cp -R ${inputs.opencode}/script ./script
        '';
      };
      opencode = upstream.opencode.overrideAttrs restoreScripts;
    in
    {
      packages.opencode = inputs.wrapper-modules.wrappers.opencode.wrap {
        inherit pkgs;
        package = opencode;
      };
      checks.opencode-craft = import ./config/test-craft.nix {
        inherit lib pkgs;
        inherit evalHome;
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) opencode;
        inherit module;
        artcraft = inputs.artcraft.homeManagerModules.default;
      };
    };
}
