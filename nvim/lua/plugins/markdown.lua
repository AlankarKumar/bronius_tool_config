return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    main = "render-markdown",
    opts = {
      enabled = true,
    },
    ft = { "markdown", "quarto" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  },
}
