return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          root_dir = require("lspconfig.util").root_pattern("tsconfig.json", "package.json", ".git"),
          init_options = {
            preferences = {
              importModuleSpecifierPreference = "relative",
            },
          },
        },
        html = {
          filetypes = { "html", "isml" },
        },
      },
    },
  },
}
