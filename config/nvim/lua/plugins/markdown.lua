return {
  -- Override the render-markdown config from the lang.markdown extra.
  -- The extra's built-in config references Snacks.toggle which crashes on
  -- LazyVim 16.0.0 because snacks.nvim isn't loaded during config().
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = {},
      },
      checkbox = {
        enabled = false,
      },
    },
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      -- Omit the Snacks.toggle that crashes. Render is toggled by filetype
      -- detection (ft = { "markdown", ... }) or manually via :RenderMarkdown.
    end,
  },
}
