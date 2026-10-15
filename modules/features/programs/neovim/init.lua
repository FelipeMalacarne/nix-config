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

-- Shared editing UI for both server and workstation variants.
for _, plugin in ipairs({
	"catppuccin-nvim",
	"blink",
	"neo-tree",
	"snacks",
	"telescope",
	"which-key",
}) do
	require("plugins." .. plugin)
end

if info.variant == "full" then
	require("config.lsp")
	require("plugins.conform")
	require("plugins.treesitter")
else
	vim.cmd("syntax enable")
end
