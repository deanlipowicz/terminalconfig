return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Merge our custom formatters into LazyVim's conform config
      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        r = { "styler" },
        quarto = { "injected" },
        sql = { "sqlfluff" },
      })
      opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        styler = {
          command = "Rscript",
          args = {
            "-e",
            "styler::style_file(commandArgs(trailingOnly = TRUE)[1])",
            "$FILENAME",
          },
          stdin = false,
        },
        sqlfluff = {
          command = "sqlfluff",
          args = { "fix", "--dialect", "duckdb", "--force", "$FILENAME" },
          stdin = false,
        },
      })
      -- Disable auto-format on save for sql via buffer-local flag
      -- (LazyVim's conform module strips opts.format_on_save, so use the intended hook)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "quarto" },
        callback = function()
          vim.b.autoformat = false
        end,
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, {
        tex = { "chktex" },
        plaintex = { "chktex" },
        r = { "lintr" },
        markdown = { "prettier_check" },
        quarto = { "prettier_check" },
        html = { "prettier_check" },
        css = { "prettier_check" },
        scss = { "prettier_check" },
        json = { "prettier_check" },
        yaml = { "prettier_check" },
        sql = { "sqlfluff" },
        javascript = { "eslint", "prettier_check" },
        javascriptreact = { "eslint", "prettier_check" },
        typescript = { "eslint", "prettier_check" },
        typescriptreact = { "eslint", "prettier_check" },
      })

      -- Custom linter: lintr (R)
      opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
        lintr = {
          cmd = "Rscript",
          args = {
            "-e",
            "lintr::lint(commandArgs(TRUE)[1])",
          },
          stdin = false,
          stream = "both",
          ignore_exitcode = true,
          parser = function(output, bufnr)
            local diagnostics = {}
            local severity = vim.diagnostic.severity
            for line in vim.gsplit(output or "", "\n", { plain = true, trimempty = true }) do
              local lnum, col, message = line:match("^.-:(%d+):(%d+):%s*(.+)$")
              if lnum and col and message then
                table.insert(diagnostics, {
                  lnum = tonumber(lnum) - 1,
                  col = tonumber(col) - 1,
                  end_lnum = tonumber(lnum) - 1,
                  end_col = tonumber(col),
                  severity = severity.WARN,
                  source = "lintr",
                  message = message,
                  bufnr = bufnr,
                })
              elseif line ~= "" then
                table.insert(diagnostics, {
                  lnum = 0, col = 0, end_lnum = 0, end_col = 0,
                  severity = severity.WARN, source = "lintr",
                  message = line, bufnr = bufnr,
                })
              end
            end
            return diagnostics
          end,
        },
        prettier_check = {
          cmd = "prettier",
          args = { "--check" },
          stdin = false,
          stream = "both",
          ignore_exitcode = true,
          parser = function(output, bufnr)
            output = vim.trim(output or "")
            if output == "" or output:match("All matched files use Prettier code style!") then
              return {}
            end
            local message = output:gsub("\n+", " ")
            return {{
              lnum = 0, col = 0, end_lnum = 0, end_col = 0,
              severity = vim.diagnostic.severity.WARN,
              source = "prettier", message = message, bufnr = bufnr,
            }}
          end,
        },
        chktex = {
          cmd = "chktex",
          args = { "-q" },
          stdin = false,
          stream = "both",
          ignore_exitcode = true,
          parser = function(output, bufnr)
            local diagnostics = {}
            local severity = vim.diagnostic.severity
            for line in vim.gsplit(output or "", "\n", { plain = true, trimempty = true }) do
              local level, code, lnum, message = line:match("^(%w+)%s+(%d+)%s+in%s+.-%s+line%s+(%d+):%s+(.+)$")
              if lnum and message then
                table.insert(diagnostics, {
                  lnum = tonumber(lnum) - 1, col = 0,
                  end_lnum = tonumber(lnum) - 1, end_col = 0,
                  severity = level == "Error" and severity.ERROR or severity.WARN,
                  source = "chktex", code = code, message = message, bufnr = bufnr,
                })
              end
            end
            return diagnostics
          end,
        },
      })
    end,
  },
}
