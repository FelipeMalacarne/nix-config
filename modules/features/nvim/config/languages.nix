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

      go = {
        enable = true;
        format.enable = false;
        extraDiagnostics.enable = true;
      };

      php = {
        enable = true;
        format.enable = false;
        extraDiagnostics.enable = true;
      };

      typescript = {
        enable = true;
        format.type = [ "prettier" ];
        extraDiagnostics.enable = true;
      };

      tsx = {
        enable = true;
        format.type = [ "prettier" ];
        extraDiagnostics.enable = false;
      };

      lua = {
        enable = true;
        lsp.lazydev.enable = true;
        format.type = [ "stylua" ];
      };

      nix = {
        enable = true;
        lsp.servers = [ "nixd" ];
        format.type = [ "nixfmt" ];
        extraDiagnostics.enable = true;
      };

      bash = {
        enable = true;
        lsp.enable = false;
        format.type = [ "shfmt" ];
        extraDiagnostics.enable = false;
      };

      css = {
        enable = true;
        lsp.enable = false;
        format.type = [ "prettier" ];
      };

      scss = {
        enable = true;
        lsp.enable = false;
        format.type = [ "prettier" ];
        extraDiagnostics.enable = false;
      };

      html = {
        enable = true;
        lsp.enable = false;
        format.enable = false;
        extraDiagnostics.enable = false;
      };

      json = {
        enable = true;
        lsp.enable = false;
        format.type = [ "prettier" ];
      };

      markdown = {
        enable = true;
        lsp.enable = false;
        format.enable = false;
        extraDiagnostics.enable = false;
      };

      yaml = {
        enable = true;
        lsp.enable = false;
      };
    };

    treesitter = {
      enable = true;
      fold = true;
      filetypeMappings = {
        tsx = [ "typescriptreact" ];
        javascript = [ "javascriptreact" ];
      };
      grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
        phpdoc
        blade
        gitcommit
        gitignore
        diff
        toml
        dockerfile
        regex
        c
      ];
    };
  };
}
