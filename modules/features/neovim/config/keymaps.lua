function _G.keybind(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- Clear search highlight
keybind("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")

-- Better window navigation
keybind("n", "<C-h>", "<C-w>h", "Move to left window")
keybind("n", "<C-j>", "<C-w>j", "Move to lower window")
keybind("n", "<C-k>", "<C-w>k", "Move to upper window")
keybind("n", "<C-l>", "<C-w>l", "Move to right window")

-- Split windows
keybind("n", "<leader>|", "<cmd>vsplit<cr>", "Vertical split")
keybind("n", "<leader>-", "<cmd>split<cr>", "Horizontal split")

-- Buffer navigation
keybind("n", "<S-h>", "<cmd>bprevious<cr>", "Previous buffer")
keybind("n", "<S-l>", "<cmd>bnext<cr>", "Next buffer")
keybind("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")

-- Stay in indent mode after shifting
keybind("v", "<", "<gv", "Indent left")
keybind("v", ">", ">gv", "Indent right")

-- Move lines up/down in visual mode
keybind("v", "J", ":m '>+1<cr>gv=gv", "Move line down")
keybind("v", "K", ":m '<-2<cr>gv=gv", "Move line up")

-- Keep cursor centered when jumping
keybind("n", "<C-d>", "<C-d>zz", "Scroll down (centered)")
keybind("n", "<C-u>", "<C-u>zz", "Scroll up (centered)")
keybind("n", "n", "nzzzv", "Next search result (centered)")
keybind("n", "N", "Nzzzv", "Prev search result (centered)")

local ui = require("config.ui")
keybind("n", "<leader>gg", ui.open_win("lazygit"), "Opens LazyGit in a floating window")
keybind("n", "<leader>gd", ui.open_win("lazydocker"), "Opens LazyDocker in a floating window")
keybind("n", "<leader>gs", ui.open_win("lazysql"), "Opens LazySQL in a floating window")
keybind("n", "<leader>gt", ui.open_win("tuxedo"), "Opens Tuxedo in a floating window")
keybind({ "n", "t" }, "<C-/>", ui.open_win(vim.o.shell, { terminal = true }), "Toggle terminal")
