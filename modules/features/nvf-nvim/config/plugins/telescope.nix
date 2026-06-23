{ pkgs, ... }:
{
  vim.telescope = {
    enable = true;
    mappings = {
      findFiles = "<leader>ff";
      liveGrep = "<leader>fg";
      buffers = "<leader>fb";
      helpTags = "<leader>fh";
      open = null;
      resume = null;
      gitFiles = null;
      gitCommits = null;
      gitBufferCommits = null;
      gitBranches = null;
      gitStatus = null;
      gitStash = null;
      lspDocumentSymbols = "<leader>fs";
      lspWorkspaceSymbols = null;
      lspReferences = null;
      lspImplementations = null;
      lspDefinitions = null;
      lspTypeDefinitions = null;
      diagnostics = "<leader>fd";
      treesitter = null;
      findProjects = null;
    };
    extensions = [
      {
        name = "fzf";
        packages = [ pkgs.vimPlugins.telescope-fzf-native-nvim ];
      }
    ];
    setupOpts.defaults = {
      prompt_prefix = "  ";
      selection_caret = " ";
      path_display = [ "truncate" ];
      sorting_strategy = "ascending";
      layout_config = {
        horizontal = {
          prompt_position = "top";
          preview_width = 0.55;
        };
        vertical.mirror = false;
        width = 0.87;
        height = 0.80;
      };
      mappings.i = {
        "<C-j>" = "move_selection_next";
        "<C-k>" = "move_selection_previous";
        "<C-q>" = "send_to_qflist";
        "<esc>" = "close";
      };
    };
  };
}
