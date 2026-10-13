return {
  "mistweaverco/kulala.nvim",
  opts = {
    -- Optional: customization options
    -- default_view = "body",
    -- global_keymaps = true, -- Enable default keymaps
  },
  keys = {
    -- Add keymaps for easy access
    { "<leader>rr", "<cmd>lua require('kulala').run()<cr>", desc = "Run Request" },
    { "<leader>rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle View" },
  },
}
