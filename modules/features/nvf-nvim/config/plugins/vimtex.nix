{ pkgs, ... }:
{
  vim.extraPlugins = {
    vimtex = {
      package = pkgs.vimPlugins.vimtex;
      setup = ''
        vim.g.tex_flavor = 'latex'
        vim.g.vimtex_view_method = 'zathura'
        vim.g.vimtex_quickfix_mode = 0
        vim.g.vimtex_compiler_method = 'latexmk'
      '';
    };
  };
}
