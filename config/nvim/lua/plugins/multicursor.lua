return {
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ["Find Under"] = "<C-n>",
        ["Add Cursor Up"] = "<C-Up>",
        ["Add Cursor Down"] = "<C-Down>",
      }
    end,
  },
}
