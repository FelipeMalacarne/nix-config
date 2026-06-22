{
  inputs,
  ...
}:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;

        settings.config_directory = ./.;

        extraPackages = with pkgs; [
          # LSPs
          lua-language-server
          gopls
          phpantom-lsp
          nixd
          typescript-go
          superhtml
          vscode-css-languageserver
          tailwindcss-language-server
          vscode-json-language-server
          marksman
          yaml-language-server

          # Formatters
          stylua
          nixfmt
          shfmt
          prettierd
          gofumpt

          # Misc Tools
          lazygit
          lazydocker
          lazysql
          tuxedo
        ];

        specs = {
          plugins = {
            data = [
              pkgs.vimPlugins.nvim-treesitter.withAllGrammars

              # telescope
              pkgs.vimPlugins.telescope-nvim
              pkgs.vimPlugins.plenary-nvim
              pkgs.vimPlugins.telescope-fzf-native-nvim

              pkgs.vimPlugins.blink-cmp
              pkgs.vimPlugins.nvim-lspconfig

              # neo-tree
              pkgs.vimPlugins.neo-tree-nvim
              pkgs.vimPlugins.nvim-web-devicons
              pkgs.vimPlugins.nui-nvim

              pkgs.vimPlugins.catppuccin-nvim
              pkgs.vimPlugins.conform-nvim
              pkgs.vimPlugins.which-key-nvim
            ];
          };

          lazyPlugins = {
            lazy = true;
            data = [
              # plugins which are not loaded until you vim.cmd.packadd them ...
            ];
          };
        };
      };
    };
}
