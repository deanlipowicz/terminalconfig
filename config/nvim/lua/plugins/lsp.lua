return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        r_language_server = {
          root_markers = { "DESCRIPTION", "NAMESPACE", ".Rbuildignore" },
        },
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },
        ts_ls = {
          filetypes = { "javascript", "jsx" },
        },
        sqls = {},
        stan_ls = {
          cmd = { "stan-language-server", "--stdio" },
          filetypes = { "stan" },
        },
        superhtml = {
          filetypes = { "html", "superhtml" },
        },
        jsonls = {
          settings = {
            json = {
              schemas = {
                {
                  description = "Vega-Lite",
                  fileMatch = { "*.vl.json", "*.vega-lite.json", "vega-lite*.json" },
                  url = "https://vega.github.io/schema/vega-lite/v6.json",
                },
                {
                  description = "Vega",
                  fileMatch = { "*.vega.json", "vega*.json" },
                  url = "https://vega.github.io/schema/vega/v6.json",
                },
              },
              validate = { enable = true },
            },
          },
        },
        eslint = {},
        biome = {},
        ["*"] = {
          keys = {
            {
              "<leader>ls",
              vim.lsp.buf.document_symbol,
              desc = "Document symbols",
            },
            {
              "<leader>ce",
              function()
                vim.lsp.buf.code_action({
                  context = { only = { "refactor.extract.function" } },
                  apply = true,
                })
              end,
              desc = "Extract function",
            },
          },
        },
      },
    },
  },
}
