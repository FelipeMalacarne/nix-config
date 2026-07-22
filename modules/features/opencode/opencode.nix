{ self, inputs, ... }:
let
  module =
    { pkgs, ... }:
    {
      programs.mcp = {
        enable = true;

        servers.playwright = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@playwright/mcp"
          ];
        };
      };

      home.sessionVariables.OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";

      xdg.configFile."opencode/oh-my-opencode-slim.json".text = builtins.toJSON {
        "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
        preset = "openai";

        multiplexer = {
          type = "herdr";
          layout = "main-vertical";
        };

        presets.openai = {
          orchestrator = {
            model = "openai/gpt-5.6-terra";
            variant = "medium";
            skills = [ "*" ];
            mcps = [
              "*"
              "!context7"
            ];
          };
          oracle = {
            model = "openai/gpt-5.6-sol";
            variant = "high";
            skills = [ "simplify" ];
            mcps = [ ];
          };
          librarian = {
            model = "openai/gpt-5.6-luna";
            variant = "low";
            skills = [ ];
            mcps = [
              "websearch"
              "context7"
              "gh_grep"
            ];
          };
          explorer = {
            model = "openai/gpt-5.6-luna";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          designer = {
            model = "openai/gpt-5.6-luna";
            variant = "medium";
            skills = [ ];
            mcps = [ ];
          };
          fixer = {
            model = "openai/gpt-5.6-luna";
            variant = "medium";
            skills = [ ];
            mcps = [ ];
          };
        };

        presets.opencode-go = {
          orchestrator = {
            model = "opencode-go/minimax-m3";
            variant = "max";
            skills = [ "*" ];
            mcps = [
              "*"
              "!context7"
            ];
          };
          oracle = {
            model = "opencode-go/qwen3.7-max";
            variant = "max";
            skills = [ "simplify" ];
            mcps = [ ];
          };
          librarian = {
            model = "opencode-go/deepseek-v4-flash";
            variant = "high";
            skills = [ ];
            mcps = [
              "websearch"
              "context7"
              "gh_grep"
            ];
          };
          explorer = {
            model = "opencode-go/deepseek-v4-flash";
            variant = "max";
            skills = [ ];
            mcps = [ ];
          };
          designer = {
            model = "opencode-go/kimi-k2.7-code";
            variant = "medium";
            skills = [ ];
            mcps = [ ];
          };
          fixer = {
            model = "opencode-go/deepseek-v4-flash";
            variant = "high";
            skills = [ ];
            mcps = [ ];
          };
          observer = {
            model = "opencode-go/mimo-v2.5";
            variant = "max";
            skills = [ ];
            mcps = [ ];
          };
        };

        disabled_agents = [ ];
      };

      programs.opencode = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

        enableMcpIntegration = true;

        tui.plugin = [ "oh-my-opencode-slim@latest" ];

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
            tail_turns = 20;
          };

          plugin = [ "oh-my-opencode-slim@latest" ];

          lsp = true;

          small_model = "opencode-go/deepseek-v4-flash";

          agent = {
            explore = {
              disable = true;
            };

            general = {
              disable = true;
            };

            title = {
              model = "opencode-go/deepseek-v4-flash";
            };

            summary = {
              model = "opencode-go/deepseek-v4-flash";
            };

            compaction = {
              model = "opencode-go/deepseek-v4-flash";
            };

            ui-dev = {
              description = "Specialized agent for UI development — Tailwind, CSS, HTML, component libraries, layouts, and responsive design";
              mode = "subagent";
              model = "opencode-go/glm-5.2";
              temperature = 0.2;
              color = "#6366f1";
            };
          };
        };

        commands = {
          "setup-ai-memory" = ./prompts/setup-ai-memory.md;
        };

        skills = {
          browser-automation = ./skills/browser-automation;
          development-workflow = ./skills/development-workflow;
          llm-wiki-memory = ./skills/llm-wiki-memory;
          nix-home-manager = ./skills/nix-home-manager;
          product-engineering = ./skills/product-engineering;
          project-harness = ./skills/project-harness;
          token-discipline = ./skills/token-discipline;
        };
      };
    };
in
{
  flake.homeModules.opencode = module;

  perSystem =
    { pkgs, ... }:
    {
      packages.opencode = inputs.wrapper-modules.wrappers.opencode.wrap {
        inherit pkgs;
      };
    };
}
