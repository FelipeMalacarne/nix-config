local dir = debug.getinfo(1, "S").source:match("^@?(.*)/")
package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path

local info = require(vim.g.nix_info_plugin_name).info
vim.g.neovim_variant = info.variant

require("config.globals")
require("config.options")
require("config.ui")
require("config.keymaps")
require("config.diagnostic")
require("config.autocmds")
if info.variant == "full" then
	require("config.lsp")
	-- Explicit ordering; configuration errors must not be silently swallowed.
	for _, plugin in ipairs({
		"catppuccin-nvim",
		"blink",
		"conform",
		"neo-tree",
		"snacks",
		"telescope",
		"treesitter",
		"which-key",
	}) do
		require("plugins." .. plugin)
	end
else
	vim.cmd("syntax enable")
end
