return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Remove parsers for languages not in my workflow (R, Stan, C++, JS/HTML/CSS)
      local remove = {
        "python", "julia", "typescript", "tsx", "xml", "yaml",
      }
      -- Ensure parsers needed for my workflow (compensates for removed extras)
      local ensure = { "cpp", "css" }
      if type(opts.ensure_installed) == "table" then
        opts.ensure_installed = vim.tbl_filter(function(lang)
          return not vim.tbl_contains(remove, lang)
        end, opts.ensure_installed)
        for _, lang in ipairs(ensure) do
          if not vim.tbl_contains(opts.ensure_installed, lang) then
            table.insert(opts.ensure_installed, lang)
          end
        end
      end
    end,
  },
}
