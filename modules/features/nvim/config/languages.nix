{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  vim = {
    lsp = {
      enable = true;
      servers = {
        "*".root_markers = [ ".git" ];

        gopls.settings.gopls = {
          analyses = {
            unusedparams = true;
            shadow = true;
          };
          staticcheck = true;
          gofumpt = true;
          hints = {
            parameterNames = true;
            assignVariableTypes = true;
            constantValues = true;
            rangeVariableTypes = true;
            compositeLiteralFields = true;
            compositeLiteralTypes = true;
            functionTypeParameters = true;
          };
        };

        lua-language-server.settings.Lua = {
          runtime.version = "LuaJIT";
          workspace = {
            checkThirdParty = false;
            library = mkLuaInline "{ vim.env.VIMRUNTIME }";
          };
          diagnostics.globals = [ "vim" ];
          hint.enable = true;
          telemetry.enable = false;
        };

        nixd.root_markers = [
          "flake.nix"
          "default.nix"
          ".git"
        ];
      };
    };

    languages = {
      enableTreesitter = true;
      enableFormat = true;

      nix = {
        enable = true;
        format.type = [ "nixfmt" ];
      };

      php = {
        enable = true;
        format.enable = false;
      };

      lua.enable = true;

      go.enable = true;

      typescript.enable = true;

      tsx.enable = true;

      html.enable = true;

      css.enable = true;

      json.enable = true;

      markdown.enable = true;

      yaml.enable = true;

      bash.enable = true;
    };

    treesitter = {
      enable = true;
      fold = true;
      grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
        phpdoc
        blade
        gitcommit
        gitignore
        diff
        toml
        dockerfile
        regex
      ];
    };
  };
}
