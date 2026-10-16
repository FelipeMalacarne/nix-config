{ self, inputs, ... }:
let
  module =
    {
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      craft = import ./config/craft-integration.nix {
        inherit lib;
        apps = osConfig.my.artcraft or { };
      };
    in
    {
      programs.mcp = {
        enable = true;

        servers = craft.servers // {
          playwright = {
            command = lib.getExe' pkgs.nodejs "npx";
            args = [
              "-y"
              "@playwright/mcp"
            ];
          };
        };
      };

      home.sessionVariables.OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";

      # xdg.configFile."opencode/oh-my-opencode-slim.json".text = builtins.toJSON {
      #   "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
      #   preset = "openai";
      #
      #   multiplexer = {
      #     type = "herdr";
      #     layout = "main-vertical";
      #   };
      #
      #   presets.openai = {
      #     orchestrator = {
      #       model = "openai/gpt-5.6-terra";
      #       variant = "medium";
      #       skills = [ "*" ];
      #       mcps = [
      #         "*"
      #         "!context7"
      #       ];
      #     };
      #     oracle = {
      #       model = "openai/gpt-5.6-sol";
      #       variant = "high";
      #       skills = [ "simplify" ];
      #       mcps = [ ];
      #     };
      #     librarian = {
      #       model = "openai/gpt-5.6-luna";
      #       variant = "low";
      #       skills = [ ];
      #       mcps = [
      #         "websearch"
      #         "context7"
      #         "gh_grep"
      #       ];
      #     };
      #     explorer = {
      #       model = "openai/gpt-5.6-luna";
      #       variant = "low";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #     designer = {
      #       model = "openai/gpt-5.6-sol";
      #       variant = "medium";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #     fixer = {
      #       model = "openai/gpt-5.6-luna";
      #       variant = "medium";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #   };
      #
      #   presets.opencode-go = {
      #     orchestrator = {
      #       model = "opencode-go/minimax-m3";
      #       variant = "max";
      #       skills = [ "*" ];
      #       mcps = [
      #         "*"
      #         "!context7"
      #       ];
      #     };
      #     oracle = {
      #       model = "opencode-go/qwen3.7-max";
      #       variant = "max";
      #       skills = [ "simplify" ];
      #       mcps = [ ];
      #     };
      #     librarian = {
      #       model = "opencode-go/deepseek-v4-flash";
      #       variant = "high";
      #       skills = [ ];
      #       mcps = [
      #         "websearch"
      #         "context7"
      #         "gh_grep"
      #       ];
      #     };
      #     explorer = {
      #       model = "opencode-go/deepseek-v4-flash";
      #       variant = "max";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #     designer = {
      #       model = "opencode-go/kimi-k2.7-code";
      #       variant = "medium";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #     fixer = {
      #       model = "opencode-go/deepseek-v4-flash";
      #       variant = "high";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #     observer = {
      #       model = "opencode-go/mimo-v2.5";
      #       variant = "max";
      #       skills = [ ];
      #       mcps = [ ];
      #     };
      #   };
      #
      #   disabled_agents = [ ];
      # };

      programs.opencode = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

        enableMcpIntegration = true;

        # tui.plugin = [ "oh-my-opencode-slim@latest" ];

        settings = {
          share = "manual";
          autoupdate = false;
          snapshot = true;

          permission = {
            external_directory = {
              "~/repos/**" = "allow";
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

          # plugin = [ "oh-my-opencode-slim@latest" ];

          lsp = true;
        }
        // craft.settings;

        skills = {
          browser-automation = ./skills/browser-automation;
          development-workflow = ./skills/development-workflow;
          nix-home-manager = ./skills/nix-home-manager;
          product-engineering = ./skills/product-engineering;
          project-harness = ./skills/project-harness;
          token-discipline = ./skills/token-discipline;
        }
        // craft.skills;
      };
    };
in
{
  flake.modules.homeManager.opencode = module;

  perSystem =
    { lib, pkgs, ... }:
    let
      upstream = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system};
      restoreScripts = old: {
        # Upstream's source filter omits script/, which the CLI build imports.
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
        inherit (inputs) home-manager;
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) opencode;
        inherit module;
      };
    };
}
