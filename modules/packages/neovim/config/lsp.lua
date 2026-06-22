vim.lsp.config("*", {
	root_markers = { ".git" },
})

vim.lsp.enable({
	"lua_ls",
	"nixd",
	"gopls",
	"phpantom-lsp",
	"tsgo",
	"superhtml",
	"tailwindcss",
	"cssls",
	"jsonls",
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("config.lsp.keymaps", { clear = true }),
	callback = function(ev)
		local map = vim.keymap.set
		local opts = function(desc)
			return { buffer = ev.buf, desc = desc }
		end

		map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
		map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
		map("n", "gy", vim.lsp.buf.type_definition, opts("Go to type definition"))
		map("n", "gr", vim.lsp.buf.references, opts("References"))
		map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
		map("n", "K", vim.lsp.buf.hover, opts("Hover docs"))
		map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
		map("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
		map("n", "<leader>f", function()
			vim.lsp.buf.format({ async = true })
		end, opts("Format buffer"))

		map("n", "<leader>d", vim.diagnostic.open_float, opts("Show diagnostics"))
	end,
})
