{ ... }:
{
  vim.keymaps = [
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<cr>";
      desc = "Clear search highlight";
    }
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      desc = "Move to left window";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      desc = "Move to lower window";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      desc = "Move to upper window";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      desc = "Move to right window";
    }
    {
      mode = "n";
      key = "<leader>|";
      action = "<cmd>vsplit<cr>";
      desc = "Vertical split";
    }
    {
      mode = "n";
      key = "<leader>-";
      action = "<cmd>split<cr>";
      desc = "Horizontal split";
    }
    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>bprevious<cr>";
      desc = "Previous buffer";
    }
    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>bnext<cr>";
      desc = "Next buffer";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<cr>";
      desc = "Delete buffer";
    }
    {
      mode = "v";
      key = "<";
      action = "<gv";
      desc = "Indent left";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      desc = "Indent right";
    }
    {
      mode = "v";
      key = "J";
      action = ":m '>+1<cr>gv=gv";
      desc = "Move line down";
    }
    {
      mode = "v";
      key = "K";
      action = ":m '<-2<cr>gv=gv";
      desc = "Move line up";
    }
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
      desc = "Scroll down (centered)";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
      desc = "Scroll up (centered)";
    }
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
      desc = "Next search result (centered)";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
      desc = "Prev search result (centered)";
    }
    {
      mode = [
        "n"
        "i"
      ];
      key = "<C-s>";
      action = "<cmd>w<cr><esc>";
      desc = "Save file";
    }
    {
      mode = "n";
      key = "<leader>cd";
      action = "vim.diagnostic.open_float";
      lua = true;
      desc = "Code diagnostics";
    }
    {
      mode = "n";
      key = "<leader><leader>";
      action = "<cmd>Telescope find_files<cr>";
      desc = "Find files";
    }
    {
      mode = "n";
      key = "<leader>fr";
      action = "<cmd>Telescope oldfiles<cr>";
      desc = "Recent files";
    }
    {
      mode = "n";
      key = "<leader>fw";
      action = "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>";
      desc = "Workspace symbols";
    }
    {
      mode = "n";
      key = "<leader>/";
      action = "<cmd>Telescope current_buffer_fuzzy_find<cr>";
      desc = "Fuzzy find in buffer";
    }
    {
      mode = "n";
      key = "<leader>z";
      action = "function() Snacks.zen() end";
      lua = true;
      desc = "Zen mode";
    }
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<cr>";
      desc = "Explorer (root)";
    }
    {
      mode = "n";
      key = "<leader>E";
      action = "<cmd>Neotree toggle dir=%:p:h<cr>";
      desc = "Explorer (file dir)";
    }
    {
      mode = [
        "o"
        "x"
      ];
      key = "ih";
      action = ":<C-u>Gitsigns select_hunk<cr>";
      desc = "Select hunk";
    }
    {
      mode = "n";
      key = "<leader>cf";
      action = ''function() require("conform").format({ async = true, lsp_format = "fallback" }) end'';
      lua = true;
      desc = "Format buffer (conform)";
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>j";
      action = ''function() require("mini.jump2d").start(require("mini.jump2d").builtin_opts.single_character) end'';
      lua = true;
      desc = "Jump 2D";
    }
    {
      mode = "n";
      key = "<leader>q";
      action = "<cmd>q<cr>";
      desc = "Quit";
    }
  ];
}
