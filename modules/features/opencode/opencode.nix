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

            agent = {
              build = {
                model = "openai/gpt-5.5";
              };
              plan = {
                model = "openai/gpt-5.5";
              };
              general = {
                model = "openai/gpt-5.5";
              };
              explore = {
                model = "opencode/deepseek-v4-flash";
                permission = {
                  edit = "deny";
                  bash = "ask";
                };
              };
              title = {
                model = "opencode/deepseek-v4-flash";
              };
              summary = {
                model = "opencode/deepseek-v4-flash";
              };
              compaction = {
                model = "opencode/deepseek-v4-flash";
              };
            };

            plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
          };

          skills = {
            browser-automation = ./skills/browser-automation;
            development-workflow = ./skills/development-workflow;
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
