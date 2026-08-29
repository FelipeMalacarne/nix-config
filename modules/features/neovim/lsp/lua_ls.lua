local library = { vim.env.VIMRUNTIME }
if vim.env.HYPRLAND_LUA_STUBS then
	table.insert(library, vim.env.HYPRLAND_LUA_STUBS)
end

---@type vim.lsp.Config
return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			workspace = {
				checkThirdParty = false,
				library = library,
			},
			diagnostics = {
				globals = { "vim", "hl" },
			},
			hint = {
				enable = true,
			},
			telemetry = {
				enable = false,
			},
		},
	},
}
