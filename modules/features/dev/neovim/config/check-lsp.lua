-- Verify real server initialization, completion capabilities and buffer mappings.
local root = assert(vim.env.TMPDIR) .. "/neovim-lsp"
vim.fn.mkdir(root .. "/.git", "p")
local fixtures = {
	{ server = "nil_ls", name = "default.nix", lines = { "{ answer = 42; }" } },
	{ server = "lua_ls", name = "example.lua", lines = { "local answer = 42", "return answer" } },
	{ server = "bashls", name = "example.sh", lines = { "#!/usr/bin/env bash", "echo hello" } },
}

for _, fixture in ipairs(fixtures) do
	local path = root .. "/" .. fixture.name
	vim.fn.writefile(fixture.lines, path)
	vim.cmd.edit(vim.fn.fnameescape(path))
	local bufnr = vim.api.nvim_get_current_buf()
	assert(vim.wait(30000, function()
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = fixture.server })) do
			if client.initialized then
				return true
			end
		end
		return false
	end, 50), "LSP did not initialize: " .. fixture.server)
	local client = vim.lsp.get_clients({ bufnr = bufnr, name = fixture.server })[1]
	assert(client:supports_method("textDocument/completion"), "Missing completion: " .. fixture.server)
	assert(vim.fn.maparg("gd", "n") ~= "", "Missing definition keymap")
end

assert(vim.v.errmsg == "", vim.v.errmsg)
for _, client in ipairs(vim.lsp.get_clients()) do
	client:stop(true)
end
vim.cmd("qa!")
