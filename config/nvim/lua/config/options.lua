-- Custom options that override LazyVim defaults
vim.g.maplocalleader = ","
vim.g.python3_host_prog = "/home/workstation/.local/venvs/quarto-jupyter/bin/python"

local opt = vim.opt

opt.autoread = true
opt.completeopt = { "menuone", "noinsert", "popup" }
opt.inccommand = "split"
opt.scrolloff = 6
opt.timeoutlen = 400
opt.updatetime = 250

vim.diagnostic.config({
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 2,
    source = "if_many",
  },
})
