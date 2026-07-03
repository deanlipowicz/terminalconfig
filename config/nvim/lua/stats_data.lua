local M = {}

local function word_or_selection()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]
    if start_line > end_line or (start_line == end_line and start_col > end_col) then
      start_line, end_line = end_line, start_line
      start_col, end_col = end_col, start_col
    end
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    if #lines > 0 then
      lines[1] = lines[1]:sub(start_col)
      lines[#lines] = lines[#lines]:sub(1, end_col)
      return vim.trim(table.concat(lines, " "))
    end
  end
  local word = vim.fn.expand("<cword>")
  return word ~= "" and word or nil
end

local function send(text)
  if text then
    vim.fn["slime#send"](text)
  end
end

-- Return the first non-nil value from a list of candidates, or nil.
local function first_non_nil(...)
  for _, v in ipairs({ ... }) do
    if v ~= nil then
      return v
    end
  end
  return nil
end

-- ──────────────────────────────────────────────
-- R data inspection helpers
-- ──────────────────────────────────────────────

M.r = {}

function M.r.glimpse()
  send(first_non_nil(word_or_selection(), "df") .. " |> glimpse()\n")
end

function M.r.summary()
  send(first_non_nil(word_or_selection(), "df") .. " |> summary()\n")
end

function M.r.head()
  send(first_non_nil(word_or_selection(), "df") .. " |> head()\n")
end

function M.r.str()
  send("str(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.dim()
  send("dim(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.names()
  send("names(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.skim()
  send("skimr::skim(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.tidy()
  send("broom::tidy(" .. first_non_nil(word_or_selection(), "model") .. ")\n")
end

function M.r.view()
  local target = first_non_nil(word_or_selection(), "df")
  vim.notify("View(" .. target .. ") opens in terminal if R runs interactively", vim.log.levels.INFO)
  send("View(" .. target .. ")\n")
end

function M.r.glance()
  send("broom::glance(" .. first_non_nil(word_or_selection(), "model") .. ")\n")
end

function M.r.augment()
  send("broom::augment(" .. first_non_nil(word_or_selection(), "model") .. ")\n")
end

-- ──────────────────────────────────────────────
-- R debug helpers
-- ──────────────────────────────────────────────

function M.r.debug_fun()
  send("debug(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.debugonce_fun()
  send("debugonce(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.undebug_fun()
  send("undebug(" .. first_non_nil(word_or_selection(), "df") .. ")\n")
end

function M.r.browser()
  local pos = vim.fn.getcurpos()
  vim.api.nvim_buf_set_lines(0, pos[2], pos[2], false, { "browser()" })
  vim.notify("Inserted browser() at line " .. pos[2], vim.log.levels.INFO)
end

function M.r.cstack()
  send("where\n")
end

function M.r.continue_browser()
  send("c\n")
end

function M.r.next_browser()
  send("n\n")
end

function M.r.finish_browser()
  send("finish\n")
end

function M.r.quit_browser()
  send("Q\n")
end

-- ──────────────────────────────────────────────
-- Python data inspection helpers
-- ──────────────────────────────────────────────

M.py = {}

function M.py.info()
  local target = first_non_nil(word_or_selection(), "df")
  send(target .. ".info()\n")
end

function M.py.describe()
  local target = first_non_nil(word_or_selection(), "df")
  send(target .. ".describe()\n")
end

function M.py.head()
  local target = first_non_nil(word_or_selection(), "df")
  send(target .. ".head()\n")
end

function M.py.dtypes()
  local target = first_non_nil(word_or_selection(), "df")
  send(target .. ".dtypes\n")
end

function M.py.shape()
  local target = first_non_nil(word_or_selection(), "df")
  send(target .. ".shape\n")
end

function M.py.columns()
  local target = first_non_nil(word_or_selection(), "df")
  send(target .. ".columns.tolist()\n")
end

-- ──────────────────────────────────────────────
-- Filetype-aware dispatch helpers
-- These pick the right language based on the
-- buffer filetype so the same keymap works in
-- R, Python, or Quarto/Markdown documents.
-- ──────────────────────────────────────────────

local function is_ft(ft)
  return vim.bo.filetype == ft
end

local function for_r()
  return is_ft("r") or is_ft("quarto") or is_ft("rmd") or is_ft("markdown")
end

local function for_py()
  return is_ft("python") or is_ft("quarto") or is_ft("markdown")
end

function M.inspect_glimpse()
  if for_py() then M.py.info() else M.r.glimpse() end
end

function M.inspect_summary()
  if for_py() then M.py.describe() else M.r.summary() end
end

function M.inspect_head()
  if for_py() then M.py.head() else M.r.head() end
end

function M.inspect_str()
  if for_py() then M.py.dtypes() else M.r.str() end
end

function M.inspect_dim()
  if for_py() then M.py.shape() else M.r.dim() end
end

function M.inspect_names()
  if for_py() then M.py.columns() else M.r.names() end
end

-- ──────────────────────────────────────────────
-- Setup: commands and keymaps
-- ──────────────────────────────────────────────

function M.setup()
  -- R user commands
  vim.api.nvim_create_user_command("Rglimpse", M.r.glimpse, { desc = "Send glimpse(word) to R terminal" })
  vim.api.nvim_create_user_command("Rsummary", M.r.summary, { desc = "Send summary(word) to R terminal" })
  vim.api.nvim_create_user_command("Rhead", M.r.head, { desc = "Send head(word) to R terminal" })
  vim.api.nvim_create_user_command("Rstr", M.r.str, { desc = "Send str(word) to R terminal" })
  vim.api.nvim_create_user_command("Rdim", M.r.dim, { desc = "Send dim(word) to R terminal" })
  vim.api.nvim_create_user_command("Rnames", M.r.names, { desc = "Send names(word) to R terminal" })
  vim.api.nvim_create_user_command("Rskim", M.r.skim, { desc = "Send skimr::skim(word) to R terminal" })
  vim.api.nvim_create_user_command("Rtidy", M.r.tidy, { desc = "Send broom::tidy(word) to R terminal" })
  vim.api.nvim_create_user_command("Rglance", M.r.glance, { desc = "Send broom::glance(word) to R terminal" })
  vim.api.nvim_create_user_command("Raugment", M.r.augment, { desc = "Send broom::augment(word) to R terminal" })
  vim.api.nvim_create_user_command("RView", M.r.view, { desc = "Send View(word) to R terminal" })

  -- Python user commands
  vim.api.nvim_create_user_command("Pyinfo", M.py.info, { desc = "Send df.info() to Python terminal" })
  vim.api.nvim_create_user_command("Pydescribe", M.py.describe, { desc = "Send df.describe() to Python terminal" })
  vim.api.nvim_create_user_command("Pyhead", M.py.head, { desc = "Send df.head() to Python terminal" })
  vim.api.nvim_create_user_command("Pydtypes", M.py.dtypes, { desc = "Send df.dtypes to Python terminal" })
  vim.api.nvim_create_user_command("Pyshape", M.py.shape, { desc = "Send df.shape to Python terminal" })
  vim.api.nvim_create_user_command("Pycolumns", M.py.columns, { desc = "Send df.columns.tolist() to Python terminal" })

  -- Inspect keymaps under <leader>i
  -- All dispatch by filetype: R in .r /.qmd, Python in .py /.qmd
  local map = vim.keymap.set
  local opts = { expr = false }

  map({ "n", "x" }, "<leader>ig", M.inspect_glimpse, { desc = "Inspect: glimpse / info" })
  map({ "n", "x" }, "<leader>is", M.inspect_summary, { desc = "Inspect: summary / describe" })
  map({ "n", "x" }, "<leader>ih", M.inspect_head, { desc = "Inspect: head" })
  map({ "n", "x" }, "<leader>iS", M.inspect_str, { desc = "Inspect: str / dtypes" })
  map({ "n", "x" }, "<leader>id", M.inspect_dim, { desc = "Inspect: dim / shape" })
  map({ "n", "x" }, "<leader>in", M.inspect_names, { desc = "Inspect: names / columns" })
  map({ "n", "x" }, "<leader>ik", M.r.skim, { desc = "Inspect: skimr::skim" })
  map({ "n", "x" }, "<leader>it", M.r.tidy, { desc = "Inspect: broom::tidy" })
  map({ "n", "x" }, "<leader>iv", M.r.view, { desc = "Inspect: View" })

  -- R debug keymaps under <leader>D
  map({ "n", "x" }, "<leader>Dd", M.r.debug_fun, { desc = "R debug: debug(function)" })
  map({ "n", "x" }, "<leader>Do", M.r.debugonce_fun, { desc = "R debug: debugonce(function)" })
  map({ "n", "x" }, "<leader>Du", M.r.undebug_fun, { desc = "R debug: undebug(function)" })
  map({ "n", "x" }, "<leader>Db", M.r.browser, { desc = "R debug: insert browser()" })
  map("n", "<leader>Dw", M.r.cstack, { desc = "R debug: where (call stack)" })
  map("n", "<leader>Dc", M.r.continue_browser, { desc = "R debug: continue (c)" })
  map("n", "<leader>Dn", M.r.next_browser, { desc = "R debug: next (n)" })
  map("n", "<leader>Df", M.r.finish_browser, { desc = "R debug: finish frame" })
  map("n", "<leader>DQ", M.r.quit_browser, { desc = "R debug: quit browser (Q)" })
end

return M
