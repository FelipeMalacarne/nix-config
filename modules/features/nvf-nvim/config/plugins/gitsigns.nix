{ ... }:
{
  vim.git.gitsigns = {
    enable = true;
    mappings = {
      nextHunk = "]h";
      previousHunk = "[h";
      stageHunk = "<leader>hs";
      resetHunk = "<leader>hr";
      undoStageHunk = "<leader>hu";
      stageBuffer = "<leader>hS";
      resetBuffer = "<leader>hR";
      previewHunk = "<leader>hp";
      blameLine = "<leader>hb";
      diffThis = "<leader>hd";
      diffProject = "<leader>hD";
      toggleBlame = null;
      toggleDeleted = null;
    };
    setupOpts.signs = {
      add.text = "▎";
      change.text = "▎";
      delete.text = "";
      topdelete.text = "";
      changedelete.text = "▎";
      untracked.text = "▎";
    };
  };
}
