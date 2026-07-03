return {
  {
    "quarto-dev/quarto-nvim",
    ft = { "quarto", "rmd", "markdown" },
    config = function()
      require("quarto").setup({
        lspFeatures = {
          enabled = true,
        },
        codeRunner = {
          enabled = false,  -- handled by slime.lua with multi-language routing
        },
      })

      -- Chunk navigation
      vim.keymap.set("n", "]c", function()
        require("quarto").nav_next()
      end, { desc = "Next Quarto chunk" })

      vim.keymap.set("n", "[c", function()
        require("quarto").nav_prev()
      end, { desc = "Previous Quarto chunk" })
    end,
  },
}
