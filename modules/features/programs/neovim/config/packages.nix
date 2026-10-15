{ inputs, pkgs }:
let
  inherit (pkgs) lib;

  # Keep server enablement and bundled executables in one manifest.
  servers = with pkgs; {
    lua_ls = lua-language-server;
    gopls = gopls;
    phpantom-lsp = inputs.phpantom-lsp.packages.${pkgs.stdenv.hostPlatform.system}.phpantom-lsp;
    nixd = nixd;
    tsgo = typescript-go;
    superhtml = superhtml;
    cssls = vscode-css-languageserver;
    tailwindcss = tailwindcss-language-server;
    jsonls = vscode-json-languageserver;
    marksman = marksman;
    yamlls = yaml-language-server;
    tofu_ls = tofu-ls;
    sqls = sqls;
    docker_language_server = docker-language-server;
    helm_ls = helm-ls;
  };

  wrapNeovim =
    {
      full ? false,
      dev ? false,
    }:
    inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;

      # Upstream enables remote-plugin hosts by default, even with no plugins.
      # Minimal must not pull Python, Node and Ruby (and their toolchains).
      hosts = lib.optionalAttrs (!full) {
        python3.nvim-host.enable = false;
        node.nvim-host.enable = false;
        ruby.nvim-host.enable = false;
      };

      settings.config_directory =
        if dev then
          lib.generators.mkLuaInline ''
            (function()
              local dir = vim.env.NVIM_CONFIG_DIR
              assert(dir and dir:sub(1, 1) == "/", "neovim-dev requires NVIM_CONFIG_DIR to be an absolute config directory")
              assert(vim.fn.filereadable(dir .. "/init.lua") == 1, "NVIM_CONFIG_DIR must contain init.lua")
              return dir
            end)()
          ''
        else
          ../.;

      info = {
        variant = if full then "full" else "minimal";
        servers = lib.optionals full (builtins.attrNames servers);
      };

      runtimePkgs = lib.optionals full (
        builtins.attrValues servers
        ++ (with pkgs; [
          stylua
          nixfmt
          shfmt
          prettierd
          gofumpt
          lazygit
          lazydocker
          lazysql
          tuxedo
          ripgrep
          fd
        ])
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.inotify-tools ]
      );

      specs.plugins.data = lib.optionals full (
        with pkgs.vimPlugins;
        [
          (nvim-treesitter.withPlugins (
            grammars: with grammars; [
              bash
              c
              css
              dockerfile
              go
              gomod
              gosum
              gotmpl
              html
              javascript
              json
              lua
              luadoc
              markdown
              markdown_inline
              nix
              php
              php_only
              query
              sql
              terraform
              toml
              tsx
              typescript
              vim
              vimdoc
              yaml
            ]
          ))
          telescope-nvim
          plenary-nvim
          telescope-fzf-native-nvim
          blink-cmp
          nvim-lspconfig
          neo-tree-nvim
          nvim-web-devicons
          nui-nvim
          catppuccin-nvim
          conform-nvim
          which-key-nvim
          snacks-nvim
        ]
      );
    };

  full = wrapNeovim { full = true; };
in
{
  neovim = full;
  neovim-full = full;
  neovim-minimal = wrapNeovim { };
  neovim-dev = wrapNeovim {
    full = true;
    dev = true;
  };
}
