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

        specs = {
          plugins = {
            data = [
              pkgs.vimPlugins.nvim-treesitter.withAllGrammars
              # pkgs.vimPlugins.lz-n
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
