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
          lua-language-server
          gopls
        ];

        specs = {
          plugins = {
            data = [
              pkgs.vimPlugins.nvim-treesitter.withAllGrammars
              pkgs.vimPlugins.telescope-nvim
              pkgs.vimPlugins.plenary-nvim
              pkgs.vimPlugins.telescope-fzf-native-nvim
              pkgs.vimPlugins.blink-cmp
              pkgs.vimPlugins.nvim-lspconfig
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
