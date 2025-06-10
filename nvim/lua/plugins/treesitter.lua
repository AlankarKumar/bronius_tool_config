return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "astro",
      },
      parser_install_dir = vim.fn.stdpath("data") .. "/treesitter-parsers",
    },
  },
}
