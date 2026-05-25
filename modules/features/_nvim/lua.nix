{ inputs, ... }:
let
  inherit (inputs.nvf.lib.nvim.dag) entryAfter entryBefore entryAnywhere;
in
{
  vim = {
    pluginRC = {
      dressing = entryAnywhere ''
        require("dressing").setup({})
      '';

      ts-context-commentstring = entryBefore [ "mini-comment" ] ''
        require("ts_context_commentstring").setup({ enable_autocmd = false })
      '';
    };

    luaConfigRC = {
      custom-options = entryAfter [ "optionsScript" ] ''
        local undodir = vim.fn.expand("~/.vim/undodir")
        if vim.fn.isdirectory(undodir) == 0 then
          vim.fn.mkdir(undodir, "p")
        end
        vim.opt.iskeyword:append("-")
        vim.opt.path:append("**")
        vim.opt.clipboard:append("unnamedplus")
        vim.opt.diffopt:append("linematch:60")
      '';

      custom-autocmds = entryAfter [ "pluginConfigs" ] ''
        local autocmd = vim.api.nvim_create_autocmd
        local augroup = vim.api.nvim_create_augroup

        autocmd("BufReadPost", {
          group = augroup("restore_cursor", { clear = true }),
          callback = function(ev)
            local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
            local line_count = vim.api.nvim_buf_line_count(ev.buf)
            if mark[1] > 0 and mark[1] <= line_count then
              vim.api.nvim_win_set_cursor(0, mark)
            end
          end,
        })

        autocmd("FileType", {
          group = augroup("no_auto_comment", { clear = true }),
          pattern = "*",
          callback = function()
            vim.opt_local.formatoptions:remove({ "c", "r", "o" })
          end,
        })

        autocmd("TextYankPost", {
          group = augroup("yank_highlight", { clear = true }),
          callback = function()
            vim.highlight.on_yank({ higroup = "Visual", timeout = 150 })
          end,
        })

        autocmd("VimEnter", {
          group = augroup("open_dir", { clear = true }),
          once = true,
          callback = function()
            local arg = vim.fn.argv(0)
            if arg and arg ~= "" and vim.fn.isdirectory(arg) == 1 then
              vim.cmd("cd " .. vim.fn.fnameescape(arg))
              vim.cmd("bwipeout")
            end
          end,
        })

        autocmd("VimEnter", {
          group = augroup("check_lazy_tools", { clear = true }),
          once = true,
          callback = function()
            if vim.fn.executable("lazygit") == 0 then
              vim.notify("lazygit not found in PATH - install it via your package manager", vim.log.levels.WARN)
            end
            if vim.fn.executable("lazydocker") == 0 then
              vim.notify("lazydocker not found in PATH - install it via your package manager", vim.log.levels.WARN)
            end
          end,
        })

        autocmd("VimResized", {
          group = augroup("resize_splits", { clear = true }),
          callback = function()
            vim.cmd("tabdo wincmd =")
          end,
        })

        autocmd("InsertLeave", {
          group = augroup("lint_on_insert_leave", { clear = true }),
          callback = function()
            require("lint").try_lint()
          end,
        })
      '';

      custom-lsp-keymaps = entryAfter [ "lsp-servers" ] ''
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
            map("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
            map("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))

            if vim.lsp.inlay_hint then
              map("n", "<leader>ih", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }))
              end, opts("Toggle inlay hints"))
            end
          end,
        })
      '';

      custom-statusline = entryAfter [ "theme" ] ''
        local file_icons = {
          lua = " ", python = " ", javascript = " ", typescript = " ",
          javascriptreact = " ", typescriptreact = " ", html = " ", css = " ",
          scss = " ", json = " ", markdown = " ", vim = " ", sh = " ",
          bash = " ", zsh = " ", rust = " ", go = " ", c = " ", cpp = " ",
          java = " ", php = " ", ruby = " ", swift = " ", kotlin = " ",
          dart = " ", elixir = " ", haskell = " ", sql = " ", yaml = "󰈚 ",
          toml = " ", xml = "󰗀 ", dockerfile = " ", gitcommit = " ",
          gitconfig = " ", vue = "󰡄 ", svelte = " ", astro = " ", blade = " ",
        }

        local cached_branch = ""
        local last_check = 0

        function _G.stl_git_branch()
          local now = vim.uv.now()
          if now - last_check > 5000 then
            cached_branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
            last_check = now
          end
          if cached_branch ~= "" then
            return "  " .. cached_branch .. " "
          end
          return ""
        end

        function _G.stl_file_type()
          local ft = vim.bo.filetype
          if ft == "" then
            return "  "
          end
          return (file_icons[ft] or "  ") .. ft
        end

        function _G.stl_file_size()
          local size = vim.fn.getfsize(vim.fn.expand("%"))
          if size < 0 then
            return ""
          end
          local size_str
          if size < 1024 then
            size_str = size .. "B"
          elseif size < 1024 * 1024 then
            size_str = string.format("%.1fK", size / 1024)
          else
            size_str = string.format("%.1fM", size / 1024 / 1024)
          end
          return "  " .. size_str .. " "
        end

        function _G.stl_mode_icon()
          local modes = {
            n = "   NORMAL", i = "   INSERT", v = " 󰆨 VISUAL", V = " 󰆨 V-LINE",
            ["\22"] = " 󰆨 V-BLOCK", c = "  COMMAND", s = "  SELECT",
            S = "  S-LINE", ["\19"] = "  S-BLOCK", R = "  REPLACE",
            r = "  REPLACE", ["!"] = "  SHELL", t = "  TERMINAL",
          }
          local mode = vim.fn.mode()
          return modes[mode] or ("  " .. mode)
        end

        vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })
        local group = vim.api.nvim_create_augroup("statusline", { clear = true })

        vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
          group = group,
          callback = function()
            vim.opt_local.statusline = table.concat({
              "  ",
              "%#StatusLineBold#%{v:lua.stl_mode_icon()}%#StatusLine#",
              "  %f %h%m%r",
              "%{v:lua.stl_git_branch()}",
              " %{v:lua.stl_file_type()}",
              " %{v:lua.stl_file_size()}",
              "%=",
              "  %l:%c  %P ",
            })
          end,
        })

        vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
          group = group,
          callback = function()
            vim.opt_local.statusline = "  %f %h%m%r  %{v:lua.stl_file_type()} %=  %l:%c   %P "
          end,
        })
      '';

      custom-floating-terminals = entryAfter [ "mappings" ] ''
        local float_border = "none"

        local function open_floating_term(command, state, persistent)
          if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_win_close(state.win, false)
            state.win = nil
            return
          end

          if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
            state.buf = vim.api.nvim_create_buf(false, true)
          end

          local width = math.floor(vim.o.columns * 0.9)
          local height = math.floor(vim.o.lines * 0.9)
          state.win = vim.api.nvim_open_win(state.buf, true, {
            relative = "editor",
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            style = "minimal",
            border = float_border,
          })

          if vim.bo[state.buf].buftype ~= "terminal" then
            vim.fn.termopen(command, {
              on_exit = function()
                if not persistent then
                  vim.api.nvim_buf_delete(state.buf, { force = true })
                end
                state.buf = nil
                state.win = nil
              end,
            })
          end
          vim.cmd("startinsert")
        end

        local function run_once(command)
          local state = {}
          open_floating_term(command, state, false)
        end

        vim.keymap.set("n", "<leader>gg", function() run_once("lazygit") end, { desc = "Lazygit" })
        vim.keymap.set("n", "<leader>gd", function() run_once("lazydocker") end, { desc = "Lazydocker" })
        vim.keymap.set("n", "<leader>gs", function() run_once("lazysql") end, { desc = "LazySQL" })

        local claude_state = {}
        vim.keymap.set({ "n", "t" }, "<C-g>", function()
          open_floating_term("claude", claude_state, true)
        end, { desc = "Toggle Claude Code" })

        local term_state = {}
        vim.keymap.set({ "n", "t" }, "<C-/>", function()
          open_floating_term(vim.o.shell, term_state, true)
        end, { desc = "Toggle terminal" })
      '';
    };
  };
}
