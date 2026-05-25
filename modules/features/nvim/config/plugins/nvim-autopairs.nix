{ ... }:
{
  vim.autopairs.nvim-autopairs = {
    enable = true;
    setupOpts = {
      check_ts = true;
      ts_config = {
        lua = [ "string" ];
        javascript = [ "template_string" ];
      };
      disable_filetype = [ "TelescopePrompt" ];
    };
  };
}
