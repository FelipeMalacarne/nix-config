{ pkgs, ... }:
{
  vim.extraPlugins.no-neck-pain = {
    package = pkgs.vimPlugins.no-neck-pain-nvim;
    setup = ''
      require("no-neck-pain").setup({})
    '';
  };
}
