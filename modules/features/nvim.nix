{ inputs, ... }:
let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {

      home-manager.users.${user} = {
        imports = [ inputs.nvf.homeManagerModules.default ];

        programs.nvf = {
          enable = true;

          settings = {
            vim = {
              viAlias = false;
              vimAlias = true;
              lsp = {
                enable = true;
              };

              keymaps = [
                {
                  mode = "n";
                  key = "<esc>";
                  action = "<cmd>nohlsearch<cr>";
                }

                # Window Navigation
                {
                  mode = "n";
                  key = "<leader>|";
                  action = "<cmd>vsplit<cr>";
                  desc = "Split window vertically";
                }
                {
                  mode = "n";
                  key = "<leader>-";
                  action = "<cmd>split<cr>";
                  desc = "Split window horizontally";
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
                  desc = "Move to bottom window";
                }
                {
                  mode = "n";
                  key = "<C-k>";
                  action = "<C-w>k";
                  desc = "Move to top window";
                }
                {
                  mode = "n";
                  key = "<C-l>";
                  action = "<C-w>l";
                  desc = "Move to right window";
                }

                # Buffer Navigation
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
                  desc = "Close buffer";
                }

                # -- Stay in indent mode after shifting
                # map("v", "<", "<gv", { desc = "Indent left" })
                # map("v", ">", ">gv", { desc = "Indent right" })
                {
                  mode = "v";
                  key = "<";
                  action = "<gv";
                  desc = "Indent left and stay in visual mode";
                }
                {
                  mode = "v";
                  key = ">";
                  action = ">gv";
                  desc = "Indent right and stay in visual mode";
                }

                # -- Move lines up/down in visual mode
                # map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
                # map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move line up" })
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

                # -- Keep cursor centered when jumping
                # map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
                # map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
                # map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
                # map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })
                {
                  mode = "n";
                  key = "<C-d>";
                  action = "<C-d>zz";
                  desc = "Scroll down and center";
                }
                {
                  mode = "n";
                  key = "<C-u>";
                  action = "<C-u>zz";
                  desc = "Scroll up and center";
                }
                {
                  mode = "n";
                  key = "n";
                  action = "nzzzv";
                  desc = "Next search result and center";
                }
                {
                  mode = "n";
                  key = "N";
                  action = "Nzzzv";
                  desc = "Previous search result and center";
                }

                # -- Diagnostics
                # map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Code diagnostics" })

              ];
            };
          };
        };
      };

      # home-manager.users.${user} =
      #   { config, lib, ... }:
      #   let
      #     c = config.lib.stylix.colors;
      #     palette = lib.filterAttrs (n: _: builtins.match "base[0-9A-Fa-f]{2}" n != null) c;
      #   in
      #   {
      #     home.packages = [
      #       (inputs.nvim-config.lib.mkPackage pkgs palette)
      #     ];
      #   };
    };
in
{
  flake.nixosModules.nvim = module;
  flake.darwinModules.nvim = module;
}
