# nvim-dap Setup for Python + R Debugging

**Date:** 2026-06-28
**Status:** Design approved, pending implementation

## Overview

Add debug adapter protocol (DAP) support to the Neovim config for statistical
computing. Python gets full DAP debugging via `debugpy`. R gets vim-slime-based
debug command helpers (no DAP adapter exists for R).

## Plugin Config — `lua/plugins/dap.lua`

Four plugins in a single Lazy.nvim spec file:

| Plugin | Spec name | Purpose |
|---|---|---|
| `mfussenegger/nvim-dap` | `nvim-dap` | Core DAP client |
| `rcarriga/nvim-dap-ui` | `nvim-dap-ui` | Visual debugger panels |
| `theHamsta/nvim-dap-virtual-text` | `nvim-dap-virtual-text` | Inline variable values |
| `mason-nvim-dap` | `mason-nvim-dap` | Auto-install debugpy adapter |

All four `config = function() end` blocks call into a single `setup()` function
within the same file that configures adapters, keymaps, and UI layout.

### nvim-dap config (inside setup)

**Python adapter:**

```lua
require("dap").adapters.python = {
  type = "executable",
  command = "python3",
  args = { "-m", "debugpy.adapter" },
}

require("dap").configurations.python = {
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
```

`debugpy` is auto-installed via `mason-nvim-dap` ensure_installed list — no
manual pip install needed from the user.

### nvim-dap-ui config

- Left sidebar: stack frames + watches
- Bottom: REPL
- Right sidebar: breakpoints

**Auto-open/close behavior:**

`DapStarted` autocmd → open all UI panels. `DapTerminated` autocmd → close all
UI panels. Uses `require("dapui").open()` and `.close()`.

### nvim-dap-virtual-text config

- Show virtual text when stopped at a breakpoint
- Default highlight group linked to `NonText`
- Comment mode: show all variables as virtual text below their line

## DAP Keymaps

All normal mode, no existing F-key conflicts:

| Key | Lua call | Description |
|---|---|---|
| `<F5>` | `dap.continue()` | Start / continue |
| `<F9>` | `dap.toggle_breakpoint()` | Toggle breakpoint |
| `<F10>` | `dap.step_over()` | Step over |
| `<F11>` | `dap.step_into()` | Step into |
| `<F12>` | `dap.step_out()` | Step out |
| `<leader>dc` | `dap.continue()` | Continue (laptop key alias) |
| `<leader>dt` | `dapui.toggle()` | Toggle UI panels |
| `<leader>dC` | `dap.run_to_cursor()` | Run to cursor |
| `<leader>dK` | `dapui.eval()` | Eval expression under cursor |

## R Debug Helpers — extended `lua/stats_data.lua`

Nine new functions under `stats_data.r.*`, each sends an R command via
vim-slime to the R terminal. Follows the existing pattern of data frame
inspection helpers (same file, same `send()` utility).

### Functions

| Function | R command sent | Purpose |
|---|---|---|
| `r.debug_fun()` | `debug(\{word})\n` | Mark function for debugging |
| `r.debugonce_fun()` | `debugonce(\{word})\n` | Debug once |
| `r.undebug_fun()` | `undebug(\{word})\n` | Remove debug marker |
| `r.browser()` | inserts `browser()` on next line | Set breakpoint in source |
| `r.cstack()` | `where\n` | Print call stack (in browser) |
| `r.continue_browser()` | `c\n` | Continue (in browser) |
| `r.next_browser()` | `n\n` | Next statement (in browser) |
| `r.finish_browser()` | `finish\n` | Finish frame (in browser) |
| `r.quit_browser()` | `Q\n` | Quit browser entirely |

All use `word_or_selection()` to determine the target function name, defaulting
to `"df"` when no word is under the cursor.

### Keymaps under `<leader>D`

Normal and visual mode:

| Key | Function | Description |
|---|---|---|
| `<leader>Dd` | `r.debug_fun()` | debug(function) |
| `<leader>Do` | `r.debugonce_fun()` | debugonce(function) |
| `<leader>Du` | `r.undebug_fun()` | undebug(function) |
| `<leader>Db` | `r.browser()` | Insert browser() line |
| `<leader>Dw` | `r.cstack()` | Print call stack |
| `<leader>Dc` | `r.continue_browser()` | Continue |
| `<leader>Dn` | `r.next_browser()` | Next |
| `<leader>Df` | `r.finish_browser()` | Finish frame |
| `<leader>DQ` | `r.quit_browser()` | Quit browser |

## File Changes

| File | Action | Description |
|---|---|---|
| `lua/plugins/dap.lua` | Create | 4 plugin specs + DAP config + keymaps |
| `lua/plugins/init.lua` | Modify | Add `{ import = "plugins.dap" }` to spec list |
| `lua/stats_data.lua` | Modify | Add 9 R debug functions + `<leader>D` keymaps in `.setup()` |

No changes to `lua/core/keymaps.lua` — DAP keys are self-contained in
`plugins/dap.lua`, R debug keys are in `stats_data.setup()`.

## Verification

After implementation, verify with headless Neovim:

1. `lua/plugins/dap.lua` loads without errors
2. All 4 plugins are registered in Lazy's spec list
3. All 17 + 9 R debug functions are importable
4. All DAP commands (`:lua require("dap").continue()`) resolve without error
5. No F-key conflicts in keymap listing
6. No `<leader>D` conflicts with existing mappings

## Out of Scope

- R DAP adapter (does not exist in the ecosystem)
- Virtual environment auto-detection for Python
- Multi-process or remote debugging
- `nvim-dap` R adapter via `RDbg` or similar
- Testing or CI for debug configurations
