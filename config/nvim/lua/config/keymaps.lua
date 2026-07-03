local keymap = vim.keymap.set
local stats_docs = require("stats_docs")
local stats_health = require("stats_health")
local stats_data = require("stats_data")

stats_docs.setup()
stats_health.setup()
stats_data.setup()

-- Write and make
keymap("n", "<leader>cm", function()
  vim.cmd("write")
  pcall(vim.cmd, "make")
  if #vim.fn.getqflist() > 0 then
    vim.cmd("copen")
  end
end, { desc = "Write and make" })

-- Smart paste (paste with indent adjustment)
keymap("n", "<leader>p", "]p", { desc = "Paste with indent (below)" })
keymap("n", "<leader>P", "[p", { desc = "Paste with indent (above)" })

-- Grep word to quickfix
keymap("n", "<leader>gw", function()
  local word = vim.fn.expand("<cword>")
  if word == "" then return end
  local lines = vim.fn.systemlist({ "rg", "--line-number", "--column", "--no-heading", word, "." })
  vim.fn.setqflist({}, "r", {
    title = "rg: " .. word,
    lines = lines,
    efm = "%f:%l:%c:%m",
  })
  if #vim.fn.getqflist() > 0 then vim.cmd("copen") end
end, { desc = "Grep word to quickfix" })

-- Stats documentation keymaps
keymap("n", "<leader>ch", "<cmd>StatsWorkbenchHealth<cr>", { desc = "Workbench health" })
keymap("n", "<leader>dr", stats_docs.open_r_doc, { desc = "R documentation" })
keymap("n", "<leader>dR", stats_docs.open_r_package, { desc = "R package documentation" })
keymap("n", "<leader>ds", stats_docs.open_stan_docs, { desc = "Stan documentation" })
keymap("n", "<leader>df", stats_docs.open_stan_functions, { desc = "Stan functions reference" })
keymap({ "n", "x" }, "<leader>dS", stats_docs.search_stan, { desc = "Search Stan documentation" })

-- fexec / fjump / parsecursor
keymap("n", "<leader>rx", function()
  local cmd = vim.fn.input("Run: ")
  if cmd == "" then return end
  cmd = cmd:gsub("{w}", vim.fn.expand("<cword>"))
  cmd = cmd:gsub("{f}", vim.fn.expand("%:p"))
  cmd = cmd:gsub("{l}", tostring(vim.fn.line(".")))
  cmd = cmd:gsub("{c}", tostring(vim.fn.col(".")))
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Command failed: " .. cmd, vim.log.levels.ERROR)
    return
  end
  vim.fn.setqflist({}, "r", { title = cmd, lines = lines, efm = "%f:%l:%c:%m" })
  vim.cmd("copen")
end, { desc = "Run command with placeholders" })

keymap("n", "<leader>rj", function()
  local line = vim.fn.getline(".")
  local file, lnum, col = line:match("([^:]+):(%d+):(%d+):")
  if not file then file, lnum = line:match("([^:]+):(%d+):") end
  if file and lnum then
    vim.cmd("edit " .. file)
    vim.fn.cursor(tonumber(lnum), tonumber(col or 1))
  else
    vim.notify("No file:line:col pattern on current line", vim.log.levels.WARN)
  end
end, { desc = "Jump to file:line:col under cursor" })

keymap("n", "<leader>op", function()
  local text = vim.fn.getreg("+")
  if text == "" then vim.notify("Clipboard is empty", vim.log.levels.WARN) return end
  local file, lnum, col = text:match("([^:]+):(%d+):(%d+)")
  if not file then file, lnum = text:match("([^:]+):(%d+)") end
  if file then
    file = vim.fn.fnamemodify(file, ":p")
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("edit " .. file)
      vim.fn.cursor(tonumber(lnum), tonumber(col or 1))
    end
  else
    vim.cmd("edit " .. text)
  end
end, { desc = "Open file:line:col from clipboard" })

-- DAP debug keymaps (matching old config; dap.core extra provides <leader>d prefixed)
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    local ok, dap = pcall(require, "dap")
    if ok then
      keymap("n", "<F5>", dap.continue, { desc = "DAP: continue" })
      keymap("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
      keymap("n", "<F10>", dap.step_over, { desc = "DAP: step over" })
      keymap("n", "<F11>", dap.step_into, { desc = "DAP: step into" })
      keymap("n", "<F12>", dap.step_out, { desc = "DAP: step out" })
    end
  end,
})

-- R REPL: open a terminal running R in a bottom split.
-- Use vim-slime (<leader>ss, <leader>sp, <leader>sf) to send code.
keymap("n", "<leader>R", "<cmd>botright 15split | terminal ++name=R R<cr>", { desc = "Open R terminal" })

-- Terminal mode escape
keymap("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Exit terminal mode" })
