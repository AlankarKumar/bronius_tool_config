return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    heading = {
      sign = false,
      width = "block",
      left_pad = 1,
      right_pad = 1,
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      backgrounds = { "H1Bg", "H2Bg", "H3Bg", "H4Bg", "H5Bg", "H6Bg" },
      foregrounds = { "H1Fg", "H2Fg", "H3Fg", "H4Fg", "H5Fg", "H6Fg" },
    },
    code = {
      sign = false,
      width = "block",
      left_pad = 2,
      right_pad = 2,
      border = "thin",
      inline_pad = 1,
      language_pad = 1,
      language_info = true, -- icon + name on the block border
    },
    bullet = { icons = { "•", "◦", "▪", "▫" } },
    pipe_table = { preset = "round" },
    dash = { width = 60 },
    checkbox = { unchecked = { icon = "󰄱 " }, checked = { icon = "󰱒 " } },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    local function hl()
      local set = vim.api.nvim_set_hl
      -- tokyonight palette; each heading level gets its own color
      local fg = { "#7aa2f7", "#bb9af7", "#7dcfff", "#9ece6a", "#e0af68", "#f7768e" }
      for i, c in ipairs(fg) do
        set(0, "RenderMarkdownH" .. i .. "Fg", { fg = c, bold = true })
        set(0, "RenderMarkdownH" .. i .. "Bg", { bg = "#24283b" })
      end
      set(0, "RenderMarkdownCodeInline", { fg = "#7dcfff", bg = "#292e42" })
      set(0, "RenderMarkdownCode", { bg = "#1f2335" })
      set(0, "RenderMarkdownDash", { fg = "#3b4261" })
      set(0, "RenderMarkdownTableHead", { fg = "#7aa2f7", bold = true })
      set(0, "RenderMarkdownTableRow", { fg = "#3b4261" })
    end
    hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
  end,
}
