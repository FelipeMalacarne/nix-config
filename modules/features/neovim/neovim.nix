{
  inputs,
  ...
}:
let
  wrapNeovim =
    pkgs:
    let
      phpantom-lsp-unstable = inputs.phpantom-lsp.packages.${pkgs.system}.phpantom-lsp;
    in
    inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;

      settings.config_directory = ./.;

      runtimePkgs =
        with pkgs;
        [
          # LSPs
          lua-language-server
          gopls
          phpantom-lsp-unstable
          intelephense
          nixd
          typescript-go
          superhtml
          vscode-css-languageserver
          tailwindcss-language-server
          vscode-json-languageserver
          marksman
          yaml-language-server
          tofu-ls
          sqls
          docker-language-server
          helm-ls

          # Formatters
          stylua
          nixfmt
          shfmt
          prettierd
          gofumpt
          sqlfluff
          dockerfmt

          # Misc Tools
          lazygit
          lazydocker
          lazysql
          tuxedo

          # latex
          # texlab
          # tex-fmt
          # texlive.combined.scheme-full
          # zathura
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ inotify-tools ];

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
            pkgs.vimPlugins.snacks-nvim
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

in
{
  perSystem = { pkgs, ... }: {
    packages.neovim = wrapNeovim pkgs;
  };

  flake.homeModules.neovim = { pkgs, ... }: {
    home.packages = [
      (wrapNeovim pkgs)
    ];
  };
}
