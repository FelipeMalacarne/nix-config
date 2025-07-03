return {
  "folke/snacks.nvim",
    opts = {
    -- The "invalid window id" error often comes from the indent
    -- or scope indicators trying to update on a window that just closed.
    -- Disabling them is the most reliable way to fix it.
    -- You can try re-enabling them one by one if you miss the feature.
    indent = {
      enabled = false,
    },
    scope = {
      enabled = false,
    },

    -- As an alternative to disabling them completely,
    -- you can try disabling only the autostart feature.
    -- If the error persists, use the configuration above.
    -- autostart = false,
  },
}
