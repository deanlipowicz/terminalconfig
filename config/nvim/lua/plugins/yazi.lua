return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    {
      "<leader>e",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at project root",
    },
    {
      "<leader>E",
      mode = { "n", "v" },
      "<cmd>Yazi cwd<cr>",
      desc = "Open yazi at current file's directory",
    },
    {
      "<leader>ew",
      "<cmd>Yazi quickfix<cr>",
      desc = "Send yazi-selected files to quickfix list",
    },
  },
  opts = {
    -- Replace netrw when opening directories (nvim .)
    open_for_directories = true,

    -- Floating window sizing
    floating_window_scaling_factor = 0.8,
    yazi_floating_window_winblend = 0,
    yazi_floating_window_border = "rounded",

    -- Show same-directory buffers in yazi
    highlight_hovered_buffers_in_same_directory = true,
  },
  init = function()
    -- Disable netrw so it doesn't hijack directory opening
    vim.g.loaded_netrwPlugin = 1
  end,
}
