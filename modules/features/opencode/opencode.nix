{ self, inputs, ... }:
let
  module =
    { pkgs, config, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = {
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
              };
            };

            compaction = {
              auto = true;
              tail_turns = 20;
            };

            # plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];

            lsp = true;

            small_model = "opencode-go/deepseek-v4-flash";

            agent = {
              explore = {
                model = "opencode-go/deepseek-v4-flash";
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
    };
in
{
  flake.nixosModules.opencode = module;
  flake.darwinModules.opencode = module;

  perSystem =
    { pkgs, ... }:
    {
      packages.opencode = inputs.wrapper-modules.wrappers.opencode.wrap {
        inherit pkgs;
      };
    };
}
