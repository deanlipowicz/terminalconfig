vim.bo.commentstring = "// %s"
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2
vim.bo.expandtab = true
vim.bo.makeprg = ".pi/bin/stanc-check %"

vim.keymap.set("n", "<leader>cm", function()
  vim.cmd("write")
  vim.cmd("make")
end, { buffer = true, desc = "Run Stan check" })
