-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Pass custom settings to the typescript-language-server
        ["typescript-language-server"] = {
          -- The key 'settings' is what the language server recognizes
          settings = {
            ["javascript.suggestionActions.enabled"] = true,
            ["typescript.suggestionActions.enabled"] = true,
          },
        },
      },
    },
  },
}
