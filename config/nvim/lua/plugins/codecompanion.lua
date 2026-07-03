return {
  "olimorris/codecompanion.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>ac", desc = "Toggle Pi Chat" },
    { "<leader>ai", desc = "Pi Inline Edit" },
    { "<leader>aa", desc = "Pi Actions" },
    { "<leader>af", desc = "Add Buffer to Context" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    adapters = {
      acp = {
        endpoint = "pi --mode rpc",
      },
    },
    strategies = {
      chat = {
        adapter = "acp",
      },
      inline = {
        adapter = "acp",
      },
    },
    keymaps = {
      ["<leader>ac"] = { action = "chat", desc = "Toggle Pi Chat" },
      ["<leader>ai"] = { action = "inline", desc = "Pi Inline Edit" },
      ["<leader>aa"] = { action = "action_palette", desc = "Pi Actions" },
      ["<leader>af"] = { action = "add_buffer", desc = "Add Buffer to Context" },
    },
  },
}
