local dir = debug.getinfo(1, "S").source:match("^@?(.*)/")
package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path

require("config.globals")
require("config.options")
require("config.keymaps")
require("config.lsp")

-- Auto-load all plugin configs
for _, file in ipairs(vim.fn.readdir(dir .. "/plugins")) do
	if file:match("%.lua$") then
		pcall(require, "plugins." .. file:gsub("%.lua$", ""))
	end
end
