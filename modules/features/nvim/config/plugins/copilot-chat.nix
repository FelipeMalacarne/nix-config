{ pkgs, ... }:
{
  vim.lazy.plugins."CopilotChat.nvim" = {
    package = pkgs.vimPlugins.CopilotChat-nvim;
    cmd = [
      "CopilotChat"
      "CopilotChatCommit"
    ];
    before = ''
      require("lz.n").trigger_load("copilot-lua")
    '';
    setupModule = "CopilotChat";
    setupOpts.window = {
      layout = "float";
      border = "rounded";
      width = 0.8;
      height = 0.8;
    };
    keys = [
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ap";
        action = ''function() require("CopilotChat").select_prompt() end'';
        lua = true;
        desc = "Copilot quick actions";
      }
      {
        mode = "n";
        key = "<leader>ac";
        action = ''
          function()
            require("CopilotChat").ask(
              "Write a commit message for the staged changes. Follow conventional commits format. Only output the commit message, no explanation.",
              { context = "git:staged" }
            )
          end
        '';
        lua = true;
        desc = "Copilot commit message";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>aa";
        action = ''function() require("CopilotChat").toggle() end'';
        lua = true;
        desc = "Copilot toggle chat";
      }
    ];
  };
}
