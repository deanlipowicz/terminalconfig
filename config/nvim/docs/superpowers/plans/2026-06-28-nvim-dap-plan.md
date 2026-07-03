# nvim-dap Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Python DAP debugging (debugpy) and R vim-slime debug command helpers to the Neovim config.

**Architecture:** Four Lazy.nvim plugin specs in a single `lua/plugins/dap.lua` file (nvim-dap, nvim-dap-ui, nvim-dap-virtual-text, mason-nvim-dap). R debug helpers extend the existing `lua/stats_data.lua` module with 9 new functions and `<leader>D` keymaps.

**Tech Stack:** nvim-dap, nvim-dap-ui, nvim-dap-virtual-text, mason-nvim-dap, debugpy, vim-slime, Lazy.nvim

## Global Constraints

- All plugin specs go in `lua/plugins/` and are imported in `lua/plugins/init.lua`
- R debug helpers follow the exact pattern of existing `stats_data.r.*` functions (use `send()`, `word_or_selection()`, `first_non_nil()`)
- DAP keymaps use F-keys (F5, F9-F12) and `<leader>dc/dt/dC/dK`
- R debug keymaps use `<leader>D` prefix (capital D, distinct from docs' `<leader>d`)
- All keymaps are normal mode unless noted
- No changes to `lua/core/keymaps.lua`

---

### Task 1: Create `lua/plugins/dap.lua`

**Files:**
- Create: `lua/plugins/dap.lua`

**Interfaces:**
- Consumes: mason-org/mason.nvim (already installed)
- Produces: `require("dap")`, `require("dapui")`, `require("nvim-dap-virtual-text")`, `require("mason-nvim-dap")` all configured

- [ ] **Step 1: Write plugin preamble and nvim-dap spec**

Insert the file header and the `nvim-dap` plugin spec with Python adapter configuration and F-key mappings:

```lua
return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      -- Python adapter via debugpy
      dap.adapters.python = {
        type = "executable",
        command = "python3",
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch current file",
          program = "${file}",
          pythonPath = function()
            return vim.fn.exepath("python3")
          end,
        },
      }

      -- Keymaps
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP: continue" })
      vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: step into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP: step out" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: continue" })
      vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "DAP: run to cursor" })
    end,
  },
}
```

- [ ] **Step 2: Append nvim-dap-ui spec**

Add after the nvim-dap spec:

```lua
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dapui = require("dapui")
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.50 },
              { id = "watches", size = 0.25 },
              { id = "stacks", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.50 },
              { id = "breakpoints", size = 0.50 },
            },
            position = "bottom",
            size = 12,
          },
        },
      })

      -- Auto-open/close
      vim.api.nvim_create_autocmd("User", {
        pattern = "DapStarted",
        callback = function()
          dapui.open()
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "DapTerminated",
        callback = function()
          dapui.close()
        end,
      })

      vim.keymap.set("n", "<leader>dt", dapui.toggle, { desc = "DAP: toggle UI" })
      vim.keymap.set("n", "<leader>dK", function()
        dapui.eval(nil, { enter = true })
      end, { desc = "DAP: eval under cursor" })
    end,
  },
```

- [ ] **Step 3: Append nvim-dap-virtual-text spec**

```lua
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
      highlight_changed_variables = true,
      show_stop_reason = true,
    },
  },
```

- [ ] **Step 4: Append mason-nvim-dap spec**

```lua
  {
    "mason-nvim-dap.nvim",
    dependencies = {
      "mfussenegger/nvim-dap",
      "mason-org/mason.nvim",
    },
    opts = {
      automatic_setup = true,
      ensure_installed = { "debugpy" },
    },
  },
}
```

- [ ] **Step 5: Verify headless Neovim loads the new file**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua print("dap module load OK")' '+qa!' 2>&1`
Note: This will error because `lua/plugins/init.lua` doesn't import `dap` yet — the file itself just needs to not have syntax errors.

Quick check: `luac -p /home/workstation/.config/nvim/lua/plugins/dap.lua`

---

### Task 2: Update `lua/plugins/init.lua`

**Files:**
- Modify: `lua/plugins/init.lua`

**Interfaces:**
- Consumes: Task 1 created `lua/plugins/dap.lua`
- Produces: dap plugin specs loaded by Lazy.nvim

- [ ] **Step 1: Add import line**

Add `{ import = "plugins.dap" },` after `{ import = "plugins.lsp" },` in the spec list (line 42).

- [ ] **Step 2: Verify headless boot**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua print("boot OK")' '+qa!' 2>&1`
Expected: clean exit, no errors.

---

### Task 3: Extend `lua/stats_data.lua` with R debug helpers

**Files:**
- Modify: `lua/stats_data.lua`

**Interfaces:**
- Consumes: existing `send()`, `word_or_selection()`, `first_non_nil()` helpers, `M.r` table
- Produces: 9 new `M.r.*` debug functions, 9 `<leader>D` keymaps in `.setup()`

- [ ] **Step 1: Add R debug function block after `M.r.augment()` (line 91)**

Insert after line 91 (after `end` closing `M.r.augment`):

```lua
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
```

- [ ] **Step 2: Add `<leader>D` keymaps in `.setup()`**

Before the final `end` of `M.setup()` (before line 212 `end`):

```lua
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
```

- [ ] **Step 3: Verify headless boot**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua local s = require("stats_data"); print("R debug functions:"); for k,_ in pairs(s.r) do if k:match("_fun") or k:match("_browser") or k == "cstack" then print("  " .. k) end end' '+qa!' 2>&1`
Expected: lists all 9 debug functions.

---

### Task 4: Verification

**Files:** (none)

- [ ] **Step 1: Full boot test**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua print("Full boot OK")' '+qa!' 2>&1`

- [ ] **Step 2: Verify dap module loads**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua local ok, msg = pcall(function() return require("dap") end); print(ok and "dap loaded OK" or "dap FAILED: " .. msg)' '+qa!' 2>&1`

- [ ] **Step 3: Verify DAP keymaps registered**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua local maps = vim.api.nvim_get_keymap("n"); for _,m in ipairs(maps) do if m.lhs and (m.lhs:find("F5") or m.lhs:find("F9") or m.lhs:find("F10") or m.lhs:find("F11") or m.lhs:find("F12") or m.lhs:find("leaderd")) then print(m.lhs .. " -> " .. (m.desc or "?")) end end' '+qa!' 2>&1`

Expected: lists F5, F9, F10, F11, F12 and all `<leader>d*` mappings.

- [ ] **Step 4: Verify no key conflicts**

Run: `nvim --headless -u /home/workstation/.config/nvim/init.lua '+lua local maps = vim.api.nvim_get_keymap("n"); local seen = {}; for _,m in ipairs(maps) do if seen[m.lhs] then print("DUPLICATE: " .. m.lhs) end; seen[m.lhs] = true end; print("Conflict check done")' '+qa!' 2>&1`

Expected: no "DUPLICATE" lines.
