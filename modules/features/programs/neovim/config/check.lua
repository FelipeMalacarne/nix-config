local variant = assert(vim.env.NVIM_TEST_VARIANT)
assert(vim.g.neovim_variant == variant, "Wrong editor variant")
assert(vim.v.errmsg == "", vim.v.errmsg)
local info = require(vim.g.nix_info_plugin_name).info
assert(vim.fn.maparg("<C-h>", "n") ~= "", "Missing core keymaps")
for _, plugin in ipairs({ "catppuccin", "blink.cmp", "neo-tree", "snacks", "telescope", "which-key" }) do
	assert(package.loaded[plugin], "Missing shared plugin: " .. plugin)
end
for _, key in ipairs({ "<leader>ff", "<leader>fg", "<leader>e", "<leader>?" }) do
	assert(vim.fn.maparg(key, "n") ~= "", "Missing shared keymap: " .. key)
end
assert(vim.fn.executable("rg") == 1, "Missing ripgrep")
assert(vim.fn.executable("fd") == 1, "Missing fd")

if variant == "minimal" then
	assert(vim.g.loaded_python3_provider == 0, "Minimal must disable the Python provider")
	assert(vim.g.loaded_node_provider == 0, "Minimal must disable the Node provider")
	assert(vim.g.loaded_ruby_provider == 0, "Minimal must disable the Ruby provider")
	assert(#info.servers == 0, "Minimal must not enable LSP servers")
	assert(vim.fn.maparg("<leader>gg", "n") == "", "Minimal must not reference bundled TUIs")
	assert(not pcall(require, "conform"), "Minimal must not bundle full plugins")
	assert(not pcall(require, "lspconfig"), "Minimal must not bundle LSP configs")
	assert(vim.fn.maparg("<leader>fs", "n") == "", "Minimal must not expose LSP-only keymaps")
	assert(not vim.tbl_contains(require("blink.cmp.config").sources.default, "lsp"))
	assert(vim.o.foldmethod == "indent")
else
	assert(#info.servers > 0)
	for _, server in ipairs(info.servers) do
		local config = vim.lsp.config[server]
		assert(config and config.cmd, "Missing LSP configuration: " .. server)
		local cmd = config.cmd
		if type(cmd) == "function" then
			-- Upstream may prefer project-local binaries. Capture the fallback
			-- command without actually starting a server in the build sandbox.
			local start = vim.lsp.rpc.start
			local captured
			vim.lsp.rpc.start = function(command)
				captured = command
			end
			local ok, err = pcall(cmd, {}, {})
			vim.lsp.rpc.start = start
			assert(ok, err)
			cmd = captured
		end
		assert(type(cmd) == "table", "No LSP command captured: " .. server)
		assert(vim.fn.executable(cmd[1]) == 1, "Missing LSP executable: " .. server)
	end
	assert(package.loaded["conform"], "Full plugin config was not loaded")
	assert(vim.treesitter.language.add("nix"), "Missing Nix parser")
	assert(vim.treesitter.language.add("php"), "Missing PHP parser")
end

vim.cmd("qa!")
