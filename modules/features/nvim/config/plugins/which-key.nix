{ ... }:
{
  vim.binds.whichKey = {
    enable = true;
    register = {
      "<leader>f" = "Find / Telescope";
      "<leader>g" = "Git";
      "<leader>h" = "Git hunks";
      "<leader>c" = "Code";
      "<leader>b" = "Buffer";
      "<leader>d" = "Diagnostics";
      "<leader>a" = "AI";
    };
    setupOpts.preset = "modern";
  };
}
