-- Custom autocmds

-- Auto-create parent directories when saving a new file
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("stats_remote_mkparents", { clear = true }),
  callback = function(event)
    local file = vim.fn.expand("<afile>:p")
    local dir = vim.fn.fnamemodify(file, ":h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})
