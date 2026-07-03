return {
  {
    "jpalardy/vim-slime",
    event = "VeryLazy",
    config = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_no_mappings = 1
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_default_config = {
        socket_name = "default",
        target_pane = "{last}",
      }

      -- Cell delimiter for vim-slime's native cell mode.
      vim.g.slime_cell_delimiter = "^```{"
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "r" },
        callback = function()
          vim.b.slime_cell_delimiter = "^#%%"
        end,
      })

      --- Extract the text of the current Quarto/Rmd code chunk.
      --- Returns the chunk content (without the ``` fences) or nil.
      local function extract_chunk_text()
        local ft = vim.bo.filetype
        if ft ~= "quarto" and ft ~= "rmd" and ft ~= "markdown" then
          return nil
        end
        local start = vim.fn.line(".")
        while start > 0 do
          if vim.fn.getline(start):match("^```%{") then
            break
          end
          start = start - 1
        end
        if start == 0 then
          return nil
        end
        local stop = start + 1
        while stop <= vim.fn.line("$") do
          if vim.fn.getline(stop):match("^```%s*$") then
            break
          end
          stop = stop + 1
        end
        if stop > vim.fn.line("$") then
          return nil
        end
        local lines = vim.fn.getline(start + 1, stop - 1)
        return table.concat(lines, "\n")
      end

      -- ── Send keymaps (tmux target) ─────────────────────────────────────

      -- Line send.
      vim.keymap.set("n", "<leader>ss", function()
        vim.cmd("normal! <Plug>SlimeLineSend")
      end, { desc = "Send line to tmux pane" })

      -- Visual selection send.
      vim.keymap.set("x", "<leader>ss", function()
        vim.cmd("normal! '<,'>SlimeRegionSend")
      end, { desc = "Send selection to tmux pane" })

      -- Paragraph send.
      vim.keymap.set("n", "<leader>sp", function()
        vim.cmd("normal! <Plug>SlimeParagraphSend")
      end, { desc = "Send paragraph to tmux pane" })

      -- Cell / chunk send.
      vim.keymap.set("n", "<leader>sc", function()
        local text = extract_chunk_text()
        if text then
          local paste_file = vim.g.slime_paste_file or "/tmp/slime-paste"
          vim.fn.writefile(vim.split(text, "\n"), paste_file)
        end
        vim.cmd("normal! <Plug>SlimeSendCell")
      end, { desc = "Send code cell/chunk to tmux pane" })

      -- Motion send.
      vim.keymap.set("n", "<leader>sM", "<Plug>SlimeMotionSend", { desc = "Send motion to tmux pane" })

      -- File send.
      vim.keymap.set("n", "<leader>sf", function()
        vim.cmd("%SlimeSend")
      end, { desc = "Send file to tmux pane" })

      -- Config / target selection (tmux pane picker).
      vim.keymap.set("n", "<leader>sC", "<cmd>SlimeConfig<cr>", { desc = "Select tmux target pane" })

    end,
  },
}
