---@type vim.lsp.Config
return {
	cmd = { "phpantom_lsp" },
	filetypes = { "php" },
	root_markers = { ".phpantom.toml", ".git", "composer.json" },
}
