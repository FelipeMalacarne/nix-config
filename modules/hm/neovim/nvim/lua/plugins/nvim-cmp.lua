return {
  "hrsh7th/nvim-cmp",

  -- Define 'opts' as a function
  opts = function()
    -- Move the require statement inside the function
    local cmp = require("cmp")

    -- Return the configuration table
    return {
      enabled = function()
        -- This logic is fine, as it runs when cmp is accessed
        local context = require("cmp.config.context")
        local disabled = false
        disabled = disabled or (vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "prompt")
        disabled = disabled or (vim.fn.reg_recording() ~= "")
        disabled = disabled or (vim.fn.reg_executing() ~= "")
        disabled = disabled or context.in_treesitter_capture("comment")
        return not disabled
      end,
      mapping = {
        ["<CR>"] = cmp.mapping({
          i = function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
            else
              fallback()
            end
          end,
          s = cmp.mapping.confirm({ select = true }),
          c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        }),
      },
      -- NOTE: You should also define your completion sources here
      -- sources = cmp.config.sources({
      --   { name = "nvim_lsp" },
      --   { name = "luasnip" },
      --   { name = "buffer" },
      --   { name = "path" },
      -- }),
    }
  end,
}
